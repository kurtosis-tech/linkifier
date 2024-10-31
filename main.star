postgres = import_module("github.com/kurtosis-tech/postgres-package/main.star")

def run(plan, args):
    database = postgres.run(plan, launch_adminer=True, extra_configs=["config_file=/data/hba_config/postgresql.conf", "hba_file=/data/hba_config/pg_hba.conf"])
    database_url = "postgresql://postgres:MyPassword1!@postgres/postgres".format(database.service.ip_address)
    plan.print(database_url)

    import_script = plan.upload_files(src="./import_csv.sh", name="import-data-script")
    db_csvs = plan.upload_files(src="./data/AdventureWorks2014", name="db-csvs")
    plan.run_sh(
        name="import-data",
        description="put data into database",
        # run="sleep 100000s",
        run="apk add postgresql-client && /home/import_csv.sh \"{0}\" /data".format(database_url),
        files={
            "/home": import_script,
            "/data": db_csvs
        },
    )

    connection_properties_str = read_file(src="connection.properties.tmpl")
    connection_properties_artifact = plan.render_templates(
        name="connection-properties-artifact",
        config={
            "connection.properties": struct(
                template=connection_properties_str,
                data={
                    "DB_HOST": database.service.ip_address,
                },
            )
        }
    )

    plan.add_service(
        name="linkifier",
        config=ServiceConfig(
            image=ImageBuildSpec(
                image_name="kurtosistech/linkifier",
                build_context_dir="./",
            ),
            cmd=["bash", "-c", "cp /home/connection.properties /linkifier && java -cp ./linkifier-3.2.9.jar main.CLI"],
            # cmd=["bash", "-c", "sleep 100000s"],
            files={
                "/home": connection_properties_artifact,
            }
        )
    )
