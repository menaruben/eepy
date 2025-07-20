package eepy

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
    shell: EepyShell `json:"shell"`
}

EEPY_FILE :: "eepy.jsonc"

try_create_default_eepy_config :: proc() -> bool {
    content, err := json.marshal(get_default_eepy_config())
    if err != nil {
        return false
    }

    path := get_eepy_file_path()
    ok := os.write_entire_file(path, content)
    if !ok {
        return false
    }

    return true
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
    return strings.join({os.get_current_directory(), EEPY_FILE}, "/")
}

@(private)
get_default_eepy_config :: proc() -> EepyConfig {
    eepy_commands: map[string]EepyCommand = {}
    eepy_commands["hello"] = EepyCommand{
        description = "prints an eepy hello message",
        cmd = []string{"echo", "haiii !!1! :3"}
    }

    config := EepyConfig{
        commands = eepy_commands, 
        shell = EepyShell{
            executable = "sh",
            args = []string{}
        }
    }

    return config
}