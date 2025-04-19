
# Function to check login 
checking_login() {
    user_record=$(grep "^$name," store.txt)

    if [[ -n "$user_record" ]]; then
        stored_password=$(echo "$user_record" | cut -d ',' -f2)
        role=$(echo "$user_record" | cut -d ',' -f3)
        attempt=0

        while [[ $attempt -lt 2 ]]; do
            if [[ "$password" == "$stored_password" ]]; then
                echo "Login successful! Access granted."

                if [[ "$role" == "teacher" ]]; then
                    teacher_interface
                else
                    student_interface
                fi

                return 0
            else
                ((attempt++))
                if [[ $attempt -lt 2 ]]; then
                    echo "Wrong password! Try again."
                    echo "Enter your password:"
                    read -s password
                fi
            fi
        done

        echo "You have entered the wrong password twice. Logging out of the system..."
        exit 1
    else
        echo "User not found! Please check your username."
        exit 1
    fi
}

# Function to add a new student
add_student() {
    echo "Enter Roll No:"
    read roll_no
    if (( roll_no < 0 )); then
        echo "Invalid input! Marks should be greater than 0."
        return
    fi

    # Ensure roll number is not already in the system
    if grep -q "^$roll_no," teacher.txt; then
        echo "Student with Roll No $roll_no already exists!"
        return
    fi

    echo "Enter Student Name:"
    read name
    echo "Enter Password for the student:"
    read -s password
role='student'
    echo "Enter Marks (out of 100):"
    read marks
    if ! [[ "$marks" =~ ^[0-9]+$ ]] || (( marks < 0 || marks > 100 )); then
        echo "Invalid input! Marks should be between 0 and 100."
        return
    fi

    # Calculate Grade
    if (( marks >= 90 )); then grade="A"
    elif (( marks >= 80 )); then grade="B"
    elif (( marks >= 70 )); then grade="C"
    elif (( marks >= 60 )); then grade="D"
    else grade="F"
    fi

    # Add new student record to both teacher.txt and student.txt
    echo "$roll_no,$name,$marks,$grade" >> teacher.txt
    echo "$roll_no,$name,$marks,$grade" >> student.txt

    # Save name and password to store.txt
    echo "$name,$password,$role" >> store.txt
    echo "Student added successfully!"
}
# Function to view student records in a table format
view_student_records() {
    echo "Student Records:"
    echo "------------------------------------------------------"
    printf "%-15s %-25s %-10s %-10s\n" "Roll No" "Name" "Marks" "Grade"
    echo "------------------------------------------------------"
    # Formatting with printf to ensure columns are aligned properly
    awk -F ',' '{printf "%-15s %-25s %-10s %-10s\n", $1, $2, $3, $4}' teacher.txt
    echo "------------------------------------------------------"
}

# Function to assign marks (Updated for both teacher and student files)
assigning_marks() {
    echo "Enter Roll No to assign or update marks:"
    read roll_no

    # Loop to check if roll number exists
    while ! grep -q "^$roll_no," teacher.txt; do
        echo "Incorrect Roll No! Please enter a valid Roll No:"
        read roll_no
    done

    # Get the student record from teacher.txt
    student_record=$(grep "^$roll_no," teacher.txt)

    echo "Enter Marks (out of 100):"
    read marks

    if ! [[ "$marks" =~ ^[0-9]+$ ]] || (( marks < 0 || marks > 100 )); then
        echo "Invalid input! Marks should be between 0 and 100."
        return
    fi

    # Calculate Grade
    if (( marks >= 90 )); then grade="A"
    elif (( marks >= 80 )); then grade="B"
    elif (( marks >= 70 )); then grade="C"
    elif (( marks >= 60 )); then grade="D"
    else grade="F"
    fi

    # Update the record in teacher.txt (overwrites the previous marks)
    sed -i "/^$roll_no,/s/\([0-9]\{1,\}\),\([0-9A-Za-z ]*\),[0-9]*,\([A-F]\)/\1,\2,$marks,$grade/" teacher.txt

    # Also update the student.txt file (if it exists and the format matches)
    if grep -q "^$roll_no," student.txt; then
        sed -i "/^$roll_no,/s/\([0-9]\{1,\}\),\([0-9A-Za-z ]*\),[0-9]*,\([A-F]\)/\1,\2,$marks,$grade/" student.txt
    else
        echo "Student record not found in student.txt!"
    fi

    echo "Marks updated successfully in both teacher.txt and student.txt!"
}
# Function to calculate and display CGPA

cal_gpa() {
    echo "Enter Roll No to calculate CGPA:"
    read roll_no

    student_record=$(grep "^$roll_no," teacher.txt)
    if [[ -z "$student_record" ]]; then
        echo "Student not found!"
        return
    fi

    student_marks=$(echo "$student_record" | cut -d ',' -f3)

    if [[ "$student_marks" == "-1" ]]; then
        echo "Marks not assigned yet!"
        return
    fi

    student_cgpa=$(echo "scale=2; ($student_marks / 100) * 4" | bc)

    # Extract name and grade from the existing record
    student_name=$(echo "$student_record" | cut -d ',' -f2)
    student_grade=$(echo "$student_record" | cut -d ',' -f4)

    # Prepare updated line with CGPA
    updated_record="$roll_no,$student_name,$student_marks,$student_grade,$student_cgpa"

    # Replace in teacher.txt
    sed -i "/^$roll_no,/c\\$updated_record" teacher.txt

    # Replace in student.txt if exists
    if grep -q "^$roll_no," student.txt; then
        sed -i "/^$roll_no,/c\\$updated_record" student.txt
    fi

    echo "CGPA for Roll No $roll_no: $student_cgpa (Saved to records)"
}

# Function to list passed students
student_passed() {
    echo "Passed Students:"
    awk -F ',' '$3 >= 60 {print "Roll No: "$1", Name: "$2", Marks: "$3", Grade: "$4}' teacher.txt
}

# Function to list failed students
student_failed() {
    echo "Failed Students:"
    awk -F ',' '$3 < 60 && $3 != -1 {print "Roll No: "$1", Name: "$2", Marks: "$3", Grade: "$4}' teacher.txt
}

# Function to get the logged-in student's roll number
get_student_roll_no() {
    grep "^.*,$name," student.txt | cut -d ',' -f1
}

# Function to view the logged-in student's grades
view_grades() {
    roll_no=$(get_student_roll_no)

    if [[ -z "$roll_no" ]]; then
        echo "Student record not found!"
        return
    fi

    student_record=$(grep "^$roll_no," student.txt)

    if [[ -z "$student_record" ]]; then
        echo "Student record not found!"
        return
    fi

    student_grade=$(echo "$student_record" | cut -d ',' -f4)
    echo "Your Grade: $student_grade"
}

# Function to view the logged-in student's CGPA
view_cgpa() {
    roll_no=$(get_student_roll_no)

    if [[ -z "$roll_no" ]]; then
        echo "Student record not found!"
        return
    fi

    student_cgpa=$(grep "^$roll_no," student.txt | cut -d ',' -f5)

    if [[ -z "$student_cgpa" ]]; then
        echo "CGPA not calculated yet!"
    else
        echo "Your CGPA: $student_cgpa"
    fi
}
# Function to change password for the student
change_password() {
    echo "Enter your current password:"
    read -s current_password

    # Check if current password matches
    user_record=$(grep "^$name,$current_password" store.txt)
    if [[ -z "$user_record" ]]; then
        echo "Incorrect password! Please try again."
        return
    fi

    echo "Enter your new password:"
    read -s new_password
    sed -i "s/^$name,$current_password/$name,$new_password/" store.txt
    echo "Password updated successfully!"
}

# Student Interface
student_interface() {
    while true; do
        echo "------------------------------------"
        echo " Welcome to the Student's Interface "
        echo "------------------------------------"
        echo "1. View Grades"
        echo "2. View CGPA"
        echo "3. Change Password"
        echo "4. Logout"
        echo "------------------------------------"
        echo "Enter your choice:"
        read choice

        case $choice in
            1) view_grades ;;
            2) view_cgpa ;;
            3) change_password ;;
            4) echo "Logging out..."; break ;;
            *) echo "Invalid choice, please try again." ;;
        esac
    done
}

# Teacher Interface
teacher_interface() {
    while true; do
        echo "------------------------------------"
        echo " Welcome to the Teacher's Interface "
        echo "------------------------------------"
        echo "1. Add Student"
        echo "2. View Student Records"
        echo "3. Assign/Update Marks"
        echo "4. Calculate CGPA"
        echo "5. List Passed Students"
        echo "6. List Failed Students"
        echo "7. Logout"
        echo "------------------------------------"
        echo "Enter your choice:"
        read choice

        case $choice in
            1) add_student ;;
            2) view_student_records ;;
            3) assigning_marks ;;
            4) cal_gpa ;;
            5) student_passed ;;
            6) student_failed ;;
            7) echo "Logging out..."; break ;;
            *) echo "Invalid choice, please try again." ;;
        esac
    done
}

# Main Login Process
echo "Welcome to the Student Management System"
echo "Enter your name:"
read name
echo "Enter your password:"
read -s password  # Hide password input for security

# Call the function
checking_login