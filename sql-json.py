import re
import json


select_pattern = r"(SELECT)[\S\s]*?(FROM)\s([A-Z_.]*)"
join_pattern = r"(JOIN)\s([A-Z_.]*)"
insert_pattern = r"(INSERT)\sINTO\s([A-Z._]*)(?:[\s\S]*?);"
update_pattern = r"(UPDATE)\s([A-Z._]*)(?:[\s\S]*?);"
create_pattern = r"(CREATE)\sOR\sREPLACE\sTEMPORARY\sTABLE\s([A-Z._]*)(?:[\s\S]*?);"


with open(r"sample_stored_procedure.sql") as sql_file:
    sql_content = sql_file.read()


def extract_info(statement_id, statement_type, match):
    data = {
        "statement_id": statement_id,
        "statement_type": statement_type,
        "table_names": [{"target_table": match.group(2)}]
    }

    for select in re.finditer(select_pattern, match.group(0)):
        if select.group(3):
            data["table_names"].append({
                "type": select.group(2),
                "source_table": select.group(3)
            })


    for join in re.finditer(join_pattern, match.group(0)):
        if join.group(2):
            data["table_names"].append({
                "type": join.group(1),
                "source_table": join.group(2)
            })

    return data


results = []
statement_id = 1


for insert in re.finditer(insert_pattern, sql_content):
    results.append(extract_info(statement_id, "INSERT", insert))
    statement_id += 1


for update in re.finditer(update_pattern, sql_content):
    results.append(extract_info(statement_id, "UPDATE", update))
    statement_id += 1


for create in re.finditer(create_pattern, sql_content):
    results.append(extract_info(statement_id, "CREATE", create))
    statement_id += 1


with open("sample_stored_procedure.json", "w") as sample_stored_procedure:
    json.dump(results, sample_stored_procedure, indent=4)


