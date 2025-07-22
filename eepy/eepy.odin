package eepy

import "core:io"
import "core:path/filepath"
import "core:strings"
import "core:fmt"
import "core:os"
import "core:encoding/json"

EepyCommand :: struct {
    description: string `json:"description"`, 
    cmd: []string `json:"cmd"`
}

EepyShell :: struct {
    executable: string `json:"executable"`,
    args: []string `json:"args"`
}

EepyConfig :: struct {
    commands: map[string]EepyCommand `json:"commands"`,
    shell: map[string]EepyShell `json:"shell"`
}

EEPY_FILE :: "eepy.jsonc"

try_create_default_eepy_config :: proc() -> (err_msg: string, ok: bool) {
    ok = false
    content, marshal_err := json.marshal(get_default_eepy_config())
    if marshal_err != nil {
        switch _ in marshal_err {
            case io.Error:
                err_msg = os.error_string(marshal_err.(io.Error))
                return

            case json.Marshal_Data_Error:
                err_msg = "error marshaling eepy.jsonc file"
                return
        }
    }

    path := get_eepy_file_path()
    err := os.write_entire_file_or_err(path, content)
    if err != nil {
        err_msg = os.error_string(err)
        return
    }
    ok = true
    return
}

try_get_eepy_config :: proc() -> (EepyConfig, bool) {
    path := get_eepy_file_path()
    content, ok := os.read_entire_file(path)
    if !ok {
        fmt.println("There was an error reading the file:", path)
        return EepyConfig{}, false
    }

    eepy_config: EepyConfig = {}
    err := json.unmarshal(content, &eepy_config)
    if err != nil {
        fmt.println("There was an error deserializing file content to Eepy config: ", err)
        return EepyConfig{}, false
    }

    return eepy_config, true
}

get_eepy_file_path :: proc() -> string {
    return filepath.join({os.get_current_directory(), EEPY_FILE})
}

@(private)
get_default_eepy_config :: proc() -> EepyConfig {
    eepy_commands := make(map[string]EepyCommand)
    defer delete(eepy_commands)

    eepy_commands["dummy"] = EepyCommand{
        description = "empty command",
        cmd = []string{}
    }

    eepy_shell := make(map[string]EepyShell)
    defer delete(eepy_shell)

    config := EepyConfig{
        commands = eepy_commands, 
        shell = eepy_shell
    }

    return config
}