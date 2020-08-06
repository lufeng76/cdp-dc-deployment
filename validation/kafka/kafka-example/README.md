## Spark Examples

The following is intended to show a set of Spark sample projects built against CDH 5.11. Currently only scala-based samples
are published but we have placeholders for pyspark and Java. Under scala you will find:

- Spark "batch sorter" which takes HDFS input files in the form "id,text" where id is a numeric value and text is a string
and sort the output based on the id. This is built using both the Spark 1.6 which bundles Scala 2.10.5 and Spark 2.1 which
bundles Scala 2.11.8.
