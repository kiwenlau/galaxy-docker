#/bin/bash

mv /tmp/config/job_conf.xml /root/galaxy/config/job_conf.xml
mv /tmp/config/tool_conf.xml /root/galaxy/config/tool_conf.xml
mkdir /root/galaxy/tools/swarm
mv /tmp/config/cufflinks_wrapper.xml /root/galaxy/tools/swarm/cufflinks_wrapper.xml
mv /tmp/config/cuff_macros.xml /root/galaxy/tools/swarm/cuff_macros.xml
mv /tmp/config/tophat2_wrapper.xml /root/galaxy/tools/swarm/tophat2_wrapper.xml
mv /tmp/config/tophat_macros.xml /root/galaxy/tools/swarm/tophat_macros.xml
mv /tmp/config/cuffdiff_wrapper.xml /root/galaxy/tools/swarm/cuffdiff_wrapper.xml
mv /tmp/config/cuffmerge_wrapper.xml /root/galaxy/tools/swarm/cuffmerge_wrapper.xml
