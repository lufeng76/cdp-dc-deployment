name := "KafkaExample"
version := "1.0"
scalaVersion := "2.11.6"
//autoScalaLibrary := false

javacOptions ++= Seq("-source", "1.8", "-target", "1.8")

resolvers +=  
  "Apache Repo" at "https://repository.apache.org/content/repositories/releases/"

resolvers +=  
  "cloudera-repos" at "https://repository.cloudera.com/artifactory/cloudera-repos/"

// See https://alvinalexander.com/scala/sbt-how-to-manage-project-dependencies-in-scala for % vs %%
libraryDependencies += "org.apache.kafka" % "kafka-clients" % "0.9.0-kafka-2.0.2" % "provided"
