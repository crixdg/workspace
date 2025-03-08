
ThisBuild / version := "0.1.0"

ThisBuild / scalaVersion := "2.13.13"

lazy val root = (project in file("."))
	.settings(
		name := "etl-center",
		idePackagePrefix := Some("vn.baodh.etl_center")
	)
