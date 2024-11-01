
def run(plan, args):
    plan.store_service_files(
        service_name="linkifier",
        src="/linkifier",
        name="linkifier-output",
    )