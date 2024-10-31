#!/bin/sh

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <jdbc:postgresql://URI> <csvDirectoryPath>"
    exit 1
fi

# PostgreSQL connection parameters from the provided URI
DB_URI="$1"  # The first argument is the PostgreSQL connection URI
CSV_DIR="$2" # The second argument is the directory containing CSV files

# Extract the database name
# DB_NAME=$(echo "$DB_URI" | sed -n 's|.*\/\([^?]*\).*|\1|p')
# echo "DB Name: $DB_NAME"

# Extract the database user
# DB_USER=$(echo "$DB_URI" | sed -n 's|.*//\([^:@]*\).*|\1|p')
# echo "DB User: $DB_USER"

# # Extract the database password
# DB_PASSWORD=$(echo "$DB_URI" | sed -n 's|.*:\([^@]*\)@.*|\1|p')
# echo "DB Password: $DB_PASSWORD"

# # Extract the host
# DB_HOST=$(echo "$DB_URI" | sed -n 's|.*@\([^:]*\):.*|\1|p')
# echo "DB Host: $DB_HOST"

# # Extract the port (default port for PostgreSQL is 5432 if not specified)
# DB_PORT=$(echo "$DB_URI" | sed -n 's|.*:\(.*\)/.*|\1|p')
# if [ -z "$DB_PORT" ]; then
#     DB_PORT=5432  # Default PostgreSQL port
# fi
# echo "DB Port: $DB_PORT"
DB_HOST="postgres"
echo $DB_HOST
DB_USER="postgres"
echo $DB_USER
DB_PASSWORD="MyPassword1!"
echo $DB_PASSWORD
DB_NAME="postgres"
echo $DB_NAME
DB_PORT=5432
echo $DB_PORT

# Log the start of the script
echo "Starting CSV import to PostgreSQL database '$DB_NAME'..."

# Check if the specified CSV directory exists
if [ ! -d "$CSV_DIR" ]; then
    echo "Error: The specified CSV directory '$CSV_DIR' does not exist."
    exit 1
fi

# Loop through each CSV file in the directory
for csv_file in "$CSV_DIR"/*.csv; do
    # Get the filename without extension to use as the table name
    table_name=$(basename "$csv_file" .csv)

    # Debug log for current file
    echo "Processing file: $csv_file"
    echo "Target table name: $table_name"

    # Generate the SQL to create the table by inspecting the CSV header
    header=$(head -n 1 "$csv_file")
    columns=$(echo "$header" | sed 's/,/ TEXT,/g')
    columns="${columns} TEXT"  # Append TEXT type to each column

    # Debug log for table creation SQL
    echo "Creating table '$table_name' with columns: $columns"

    # Create the table in PostgreSQL
    echo "Executing SQL to create table..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "DROP TABLE IF EXISTS \"$table_name\"; CREATE TABLE \"$table_name\" ($columns);"
    if [ $? -eq 0 ]; then
        echo "Table '$table_name' created successfully."
    else
        echo "Failed to create table '$table_name'." >&2
        continue
    fi

    # Load the CSV data into the newly created table
    echo "Loading data from $csv_file into table '$table_name'..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\COPY \"$table_name\" FROM '$csv_file' WITH CSV HEADER;"
    if [ $? -eq 0 ]; then
        echo "Data loaded successfully into '$table_name'."
    else
        echo "Failed to load data into '$table_name'." >&2
    fi
    echo "------------------------------------------"
done

echo "CSV import completed."
