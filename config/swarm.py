"""
Swarm Job Runner
"""
 
import logging
import os
import string
import subprocess
import datetime

from galaxy import model
from galaxy.jobs.runners import AsynchronousJobState, AsynchronousJobRunner

log = logging.getLogger(__name__)

__all__ = ['SwarmJobRunner']

DEFAULT_swarm_IMAGE = 'python:2.7'

DOCKER_RUN_CMD = '''docker run -d -v /opt:/opt --memory=1152m --cpu-shares=2 --name=${name} ${image} ${command}'''

DOCKER_PS_CMD = '''docker ps -a --filter "name=${name}" --format "{{.Status}}"'''

DOCKER_RM_CMD = '''docker rm -f ${name}'''

DOCKER_INSPECT_CMD = '''docker inspect ${name}'''

class SwarmJobState(AsynchronousJobState):

    def __init__(self, **kwargs):
        super(SwarmJobState, self).__init__(**kwargs)
        self.image = DEFAULT_swarm_IMAGE
        self.working_directory = ""
        self.input_datasets = [] 
        self.output_datasets = []
        self.tool = ""
        self.container_name = ""

class SwarmJobRunner(AsynchronousJobRunner):
    
    runner_name = "SwarmRunner"

    def __init__(self, app, nworkers, **kwargs):
        super(SwarmJobRunner, self).__init__(app, nworkers, **kwargs)
        self._init_monitor_thread()
        self._init_worker_threads()

    def queue_job(self, job_wrapper):

        """prepare the job"""
        if not self.prepare_job(job_wrapper, include_metadata=True):
            return

        """initialize JobState with job attributes"""
        JobState = SwarmJobState(
            files_dir=job_wrapper.working_directory,
            job_wrapper=job_wrapper,
        )
        JobState.job_id = job_wrapper.get_id_tag()
        JobState.old_state = 'new'
        JobState.image = job_wrapper.tool.containers[0].identifier
        JobState.working_directory = job_wrapper.working_directory
        JobState.input_datasets = job_wrapper.get_input_fnames()
        JobState.output_datasets = job_wrapper.get_output_fnames()
        JobState.tool = job_wrapper.tool.old_id
        JobState.container_name = "galaxyjob%s" % JobState.job_id

        """create job_file"""
        old_job_file = self.get_job_file(job_wrapper, exit_code_path=JobState.exit_code_file)
        #log.debug("old_job_file = \n\n%s\n", old_job_file)
        fh = open(JobState.job_file, "w")
        fh.write(self.update_job_file(old_job_file))
        fh.close()
        #log.debug("new_job_file = \n\n%s\n", open(JobState.job_file, 'r').read())

        """job was deleted while we are preparing it"""
        if job_wrapper.get_state() == model.Job.states.DELETED:
            log.debug("Job %s deleted by user before it entered the queue" % JobState.job_id)
            if self.app.config.cleanup_job in ("always", "onsuccess"):
                job_wrapper.cleanup()
                return

        """log basic information of the job"""
        log.debug("JobState.job_id = %s", JobState.job_id)
        log.debug("JobState.job_name = %s", JobState.job_name)
        log.debug("JobState.tool = %s", JobState.tool)
        log.debug("JobState.image = %s", JobState.image)
        log.debug("JobState.container_name = %s", JobState.container_name)
        log.debug("JobState.working_directory = %s", JobState.working_directory)
        for i in range(len(JobState.input_datasets)):
            log.debug("input_dataset = %s" % JobState.input_datasets[i])
        for i in range(len(JobState.output_datasets)):
            log.debug("output_dataset = %s" % JobState.output_datasets[i])

        """submit job to swarm cluster"""
        self.submit_job(JobState)

        # put job into queue for monitor
        self.monitor_queue.put(JobState)

    def submit_job(self, JobState):

        """generate tool_script"""
        tool_script = "%s/tool_script.sh" % JobState.working_directory
        self.update_tool_script(JobState, tool_script)

        """generate "docker run" command to run docker container"""
        docker_cmd = string.Template(DOCKER_RUN_CMD)
        docker_cmd = docker_cmd.substitute(name = JobState.container_name, image = JobState.image, command = tool_script)
        log.debug("docker command = %s", docker_cmd)

        """execute "docker run" command in a new process"""
        JobState.begin_time = datetime.datetime.now() 
        # self.execute_command(docker_cmd)
        docker_run_process = self.execute_docker_run(docker_cmd)

        # JobState.docker_run_process = docker_run_process

        # write job result to galaxy
        open(JobState.exit_code_file, 'w').write('0')
        open(JobState.output_file, 'w').write('')
        open(JobState.error_file, 'w').write('')

    def check_watched_items(self):

        new_watched = []
        for JobState in self.watched:

            if JobState.old_state == model.Job.states.NEW:
                log.debug('(%s) Job state changed to queued', JobState.job_id)
                JobState.job_wrapper.change_state(model.Job.states.QUEUED)
                JobState.old_state = model.Job.states.QUEUED

            elif JobState.old_state == model.Job.states.QUEUED:
                log.debug('(%s) current Job state is queued', JobState.job_id)
                state = self.get_job_status(JobState)
                if state == model.Job.states.RUNNING:
                    JobState.running = True
                    JobState.job_wrapper.change_state(model.Job.states.RUNNING)
                    JobState.old_state = model.Job.states.RUNNING
                elif state == model.Job.states.ERROR:
                    log.debug('(%s) Job failed', JobState.job_id)
                    self.work_queue.put((self.finish_job, JobState))
                    continue
                elif state == model.Job.states.OK:
                    log.debug('(%s) Job has completed', JobState.job_id)
                    self.work_queue.put((self.finish_job, JobState))
                    continue

            elif JobState.old_state == model.Job.states.RUNNING:
                state = self.get_job_status(JobState)
                if state == model.Job.states.OK:
                    log.debug('(%s) Job has completed', JobState.job_id)
                    self.work_queue.put((self.finish_job, JobState))
                    continue
                elif state == model.Job.states.ERROR:
                    log.debug('(%s) Job failed', JobState.job_id)
                    self.work_queue.put((self.finish_job, JobState))
                    continue

            new_watched.append(JobState)

        self.watched = new_watched

    def get_job_status(self, JobState):

        # out=JobState.docker_run_process.stdout.read()
        # log.debug(out)

        # generate "docker ps" command to check container status
        docker_cmd = string.Template(DOCKER_PS_CMD)
        docker_cmd = docker_cmd.substitute(name=JobState.container_name)
        log.debug("docker command=%s", docker_cmd)
        
        # execute "docker ps" command in a new process
        stdout, stderr = self.execute_command(docker_cmd)

        # determine the job status according to the output of "docker get" command
        if 0 < stdout.count('Up'):
            log.debug("container %s is running.", JobState.container_name)
            return model.Job.states.RUNNING
        elif 0 < stdout.count('Exited (0)'):
            log.debug("container %s has succeeded.", JobState.container_name)

            #cp_cmp = "cp -r %s /opt/in" % JobState.working_directory
            #self.execute_command(cp_cmp)

            # execute job_file
            script_cmd = "/bin/sh " + JobState.job_file
            log.debug("job_file=%s", JobState.job_file)
            self.execute_command(script_cmd)

            #cp_cmp = "cp -r %s /opt/out" % JobState.working_directory
            #self.execute_command(cp_cmp)
            
            self.finish_container(JobState)
                       
            JobState.end_time = datetime.datetime.now()
            JobState.execute_time = (JobState.end_time - JobState.begin_time).seconds 
            log.debug("\nEXECUTE TIME (seconds)=%s;Galaxy Job ID=%s;Success=TRUE;Tool=%s;Docker image=%s;Input data=%s", JobState.execute_time, JobState.job_id, JobState.tool, JobState.image, JobState.input_datasets[0])

            return model.Job.states.OK          
        elif 0 < stdout.count('ExitCode:1'):
            log.error("container (%s) failed: %s", JobState.job_id, JobState.job_id)

            self.finish_container(JobState)

            JobState.end_time = datetime.datetime.now()
            JobState.execute_time = (JobState.end_time - JobState.begin_time).seconds      
            log.debug("\nEXECUTE TIME (seconds)=%s;Galaxy Job ID=%s;Success=FALSE;Tool=%s;Docker image=%s;Input data=%s", JobState.execute_time, JobState.job_id, JobState.tool, JobState.image, JobState.input_datasets[0]) 

            return model.Job.states.ERROR
        else:
            return model.Job.states.QUEUED

    def update_job_file(self, old_job_file): 
        """delete docker command"""      
        new_job_file = ""
        for line in old_job_file.split('; '):
            if 0 < line.count('docker '):
                continue
            new_job_file += line + '\n'
        return new_job_file

    def update_tool_script(self, JobState, tool_script):
        """add cd command to change to working directory"""
        chdir_cmd = "#!/bin/sh\ncd %s;" % JobState.working_directory
        tool_script_content = open(tool_script, "r").read()
        tool_script_content = tool_script_content.replace("#!/bin/sh\n", chdir_cmd)
        f = open(tool_script, "w")
        f.write(tool_script_content)
        f.close()

    def execute_docker_run(self, command):
        proc = subprocess.Popen(args=command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=os.environ.copy(), preexec_fn=os.setpgrp)
        return proc

    def execute_command(self, command):
        proc = subprocess.Popen(args=command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=os.environ.copy(), preexec_fn=os.setpgrp)
        stdout, stderr = proc.communicate()
        log.debug("\"%s\" stdout =\n%s", command, stdout)
        log.debug("\"%s\" stderr =\n%s", command, stderr)
        return [stdout, stderr]

    def finish_container(self, JobState):

        # generate "docker inspect" command to check container information
        docker_cmd = string.Template(DOCKER_INSPECT_CMD)
        docker_cmd = docker_cmd.substitute(name=JobState.container_name)
        log.debug("docker command=%s", docker_cmd)
        
        # execute "docker rm" command in a new process
        self.execute_command(docker_cmd)
        
        # generate "docker ps" command to delete the container
        docker_cmd = string.Template(DOCKER_RM_CMD)
        docker_cmd = docker_cmd.substitute(name=JobState.container_name)
        log.debug("docker command=%s", docker_cmd)
        
        # execute "docker rm" command in a new process
        self.execute_command(docker_cmd)


