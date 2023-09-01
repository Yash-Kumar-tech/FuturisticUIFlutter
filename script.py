import os

def count_lines_of_code(path):
    total_lines = 0
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(".dart"):
                with open(os.path.join(root, file), "r") as f:
                    total_lines += len(f.readlines())
    return total_lines

print(count_lines_of_code("/lib"))
