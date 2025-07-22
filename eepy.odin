package main

import "core:os/os2"
import "core:io"
/*
    eepy is just a simple tool to declare commands in a jsonc file (like a minimal project)
    and then run them from the command line with `eepy <command_name>`. 

    In the future, I would like to add only a few more features like:
    - support for different shells depending on the OS
    - environments (with variables, different commands)
    - variable substitution in commands
*/

import "core:strings"
import "core:fmt"
import "core:encoding/json"
import "core:os"
import "eepy"

main :: proc() {
    if len(os.args) < 2 {
        config, ok := eepy.try_get_eepy_config()
        if !ok {
            if !try_handle_no_eepy_config() {
                return
            }
        }
        fmt.println("Usage: eepy <command_name>")
        return
    }

    command := os.args[1]
    eepy_config, ok := eepy.try_get_eepy_config()
    if !ok {
        fmt.println("Failed to load eepy config.")
        return
    }

    run_command(eepy_config, command)
}

run_command :: proc(config: eepy.EepyConfig, command: string) {
    eepy_command, exists := config.commands[command]
    if !exists {
        fmt.println("Command not found:", command)
        return
    }

    executable_command := []string{
        config.shell.executable, 
        strings.join(config.shell.args, " "),
        strings.join(eepy_command.cmd, " "),
    }

    fmt.println("[CMD]:", strings.join(eepy_command.cmd, " "))
    process, perr := os2.process_start({
        command = executable_command,
        env = os.environ(),
        stdout = os2.stdout,
        stderr = os2.stderr,
        stdin = os2.stdin,
    })
    if perr != nil {
        fmt.println("Error starting process:", perr)
        return
    }
    defer _ = os2.process_close(process)

    state: os2.Process_State
    state, perr = os2.process_wait(process)
    if state.exit_code != 0 {
        fmt.println("[INFO]: exited with exit code:", state)
        return
    } 
    
    fmt.println("[INFO]: executed successfully")
}

try_handle_no_eepy_config :: proc() -> bool {    
    fmt.println("No eepy.json file found in the current directory. Do you want to create one? (y/n)")
    choice: []byte = make([]byte, 1)
    defer delete(choice)
    choice_str: string

    for choice_str != "y" && choice_str != "n" {
        _, err := os.read(os.stdin, choice)
        if err != nil {
            fmt.println("Error reading input:", err)
            return false
        }

        choice_str, err = strings.to_lower(string(choice[:]))
        if err != nil {
            fmt.println("Error converting input to string:", err)
            return false
        }
    }

    switch choice_str {
        case "n":
            fmt.println("Bye byeee... :(")
            return false
        
        case "y":
            fmt.printfln("Yay, let's create your eepy file at %s", eepy.get_eepy_file_path())
            err_msg, create_ok := eepy.try_create_default_eepy_config()
            if !create_ok {
                fmt.println(err_msg)
                return false
            }

            fmt.println("Successfully created eepy.jsonc file! Happy eepy-ing :3")
    }
    
    return true
}