 kafka-sentry -cr -r admin
 kafka-sentry -arg -g ibm_sap -r admin
 kafka-sentry -gpr -r admin -p "Host=*->Cluster=kafka-cluster->action=create"
 kafka-sentry -gpr -r admin -p "Host=*->Topic=mytopic->action=all"
 kafka-sentry -gpr -r admin -p "Host=*->Topic=mytopic->action=describe"
#kafka-sentry -gpr -r admin -p "Host=*->Topic=mytopic->action=write"
 kafka-sentry -gpr -r admin -p "Host=*->Topic=__consumer_offsets->action=all"
 kafka-sentry -gpr -r admin -p "Host=*->Consumergroup=myconsumergroup->action=all"

 kafka-sentry -cr -r users
 kafka-sentry -arg -g internet -r users
 kafka-sentry -gpr -r users -p "Host=*->Topic=mytopic->action=read"
 kafka-sentry -gpr -r users -p "Host=*->Topic=__consumer_offsets->action=all"
 kafka-sentry -gpr -r users -p "Host=*->Consumergroup=myconsumergroup->action=read"
 kafka-sentry -gpr -r users -p "Host=*->Consumergroup=myconsumergroup->action=describe"
