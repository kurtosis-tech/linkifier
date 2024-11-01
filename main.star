postgres = import_module("github.com/kurtosis-tech/postgres-package/main.star")

def run(plan, args):
    # database = postgres.run(plan, launch_adminer=True, extra_configs=["hba_file=/data/hba_config/pg_hba.conf"])
    database = postgres.run(plan, launch_adminer=True)
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
            cmd=["bash", "-c", "cp /home/connection.properties /linkifier && java -cp ./linkifier-3.2.9.jar main.CLI && sleep 10000s"],
            files={
                "/home": connection_properties_artifact,
            },
        )
    )

    # This fails in runtime if response["code"] != 200 for each request in a 5 minute time span
    # plan.wait(
    #     # A Service name designating a service that already exists inside the enclave
    #     # If it does not, a validation error will be thrown
    #     # MANDATORY
    #     service_name = "linkifier",

    #     # The recipe that will be run until assert passes.
    #     # Valid values are of the following types: (ExecRecipe, GetHttpRequestRecipe, PostHttpRequestRecipe)
    #     # MANDATORY
    #     recipe = ExecRecipe(
    #         command=["/bin/sh", "-c", "ls -la "]
    #     ),

    #     # Wait will use the response's field to do the asssertions. To learn more about available fields, 
    #     # that can be used for assertions, please refer to exec and request instructions.
    #     # MANDATORY
    #     field = "code",

    #     # The assertion is the comparison operation between value and target_value.
    #     # Valid values are "==", "!=", ">=", "<=", ">", "<" or "IN" and "NOT_IN" (if target_value is list).
    #     # MANDATORY
    #     assertion = "==",

    #     # The target value that value will be compared against.
    #     # MANDATORY
    #     target_value = 200,

    #     # The interval value is the initial interval suggestion for the command to wait between calls
    #     # It follows a exponential backoff process, where the i-th backoff interval is rand(0.5, 1.5)*interval*2^i
    #     # Follows Go "time.Duration" format https://pkg.go.dev/time#ParseDuration
    #     # OPTIONAL (Default: "1s")
    #     interval = "1s",

    #     # The timeout value is the maximum time that the command waits for the assertion to be true
    #     # Follows Go "time.Duration" format https://pkg.go.dev/time#ParseDuration
    #     # OPTIONAL (Default: "10s")
    #     timeout = "5m",

    #     # A human friendly description for the end user of the package
    #     # OPTIONAL (Default: Waiting for at most 'TIMEOUT' for service 'SERVICE_NAME' to reach a certain state)
    #     description = "waiting for csvs to be output"  
    # )

    plan.store_service_files(
        service_name="linkifier",
        src="./linkifier",
        name="linkifier-output",
    )