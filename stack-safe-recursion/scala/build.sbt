ThisBuild / scalaVersion := "3.8.3"
ThisBuild / version := "0.1.0"

lazy val root = (project in file("."))
  .settings(
    name := "stack-safe-recursion",
    scalacOptions ++= Seq(
      "-deprecation",
      "-feature",
      "-unchecked",
      "-Wunused:all"
    )
  )
