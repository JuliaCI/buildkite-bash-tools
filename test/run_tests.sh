#!/usr/bin/env ./bats/bin/bats

load 'bats-support/load'
load 'bats-assert/load'

# Load our library code
source '../lib/glob.sh'
source '../lib/treehash.sh'


function create_test_tree() {
    mkdir -p "A"
    echo "Hello There" > "A/general_kenobi.txt"
    mkdir -p "B/empty_dir"
    echo "For Science" > "B/you_monster.exe"
    echo "1554" > "black_mesa_east.password"
}

# First, globbing
@test "collect_glob_pattern (dir)" {
    dir="$(mktemp -d)"
    pushd "${dir}"
    create_test_tree

    # ${dir} finds all files within the prefix
    run collect_glob_pattern "${dir}"
    assert_output --partial "${dir}/A/general_kenobi.txt"
    assert_output --partial "${dir}/B/you_monster.exe"
    assert_output --partial "${dir}/black_mesa_east.password"
    refute_output --partial "${dir}/B/empty_dir"
    assert_success

    # ${dir}/**/* also finds all files within the prefix
    run collect_glob_pattern "${dir}/**/*"
    assert_output --partial "${dir}/A/general_kenobi.txt"
    assert_output --partial "${dir}/B/you_monster.exe"
    assert_output --partial "${dir}/black_mesa_east.password"
    refute_output --partial "${dir}/B/empty_dir"
    assert_success

    # ./**/* also finds all files within the prefix
    run collect_glob_pattern "./**/*"
    assert_output --partial "./A/general_kenobi.txt"
    assert_output --partial "./B/you_monster.exe"
    assert_output --partial "./black_mesa_east.password"
    refute_output --partial "./B/empty_dir"
    assert_success

    # ${dir}/* only finds a top-level file
    run collect_glob_pattern "${dir}/*"
    refute_output --partial "${dir}/A/general_kenobi.txt"
    refute_output --partial "${dir}/B/you_monster.exe"
    assert_output --partial "${dir}/black_mesa_east.password"
    refute_output --partial "${dir}/B/empty_dir"
    assert_success

    # ${dir}/* only finds a top-level file
    run collect_glob_pattern "*"
    refute_output --partial "A/general_kenobi.txt"
    refute_output --partial "B/you_monster.exe"
    assert_output --partial "black_mesa_east.password"
    refute_output --partial "B/empty_dir"
    assert_success

    # Advanced globbing!
    run collect_glob_pattern "${dir}/**/*.txt"
    assert_output --partial "${dir}/A/general_kenobi.txt"
    refute_output --partial "${dir}/B/you_monster.exe"
    refute_output --partial "${dir}/black_mesa_east.password"
    refute_output --partial "${dir}/B/empty_dir"
    assert_success

    run collect_glob_pattern "./**/*.txt"
    assert_output --partial "./A/general_kenobi.txt"
    refute_output --partial "./B/you_monster.exe"
    refute_output --partial "./black_mesa_east.password"
    refute_output --partial "./B/empty_dir"
    assert_success

    popd
    rm -rf "${dir}"
}


# Next, treehashing
function collect_treehash() {
    collect_glob_pattern "${1}" | calc_treehash
}

@test "calc_treehash" {
    dir="$(mktemp -d)"
    pushd "${dir}"
    create_test_tree

    # "." finds all files within the prefix
    run collect_treehash "."
    assert_output "045920f7394d11e513a8d518bc5d5fb28174c8a2fd32b7e285bc6bca8f8b30ac"
    assert_success

    # Grabbing the whole directory by name works too
    run collect_treehash "${dir}"
    assert_output "045920f7394d11e513a8d518bc5d5fb28174c8a2fd32b7e285bc6bca8f8b30ac"
    assert_success

    # Globbing differently gives exactly the same treehash
    run collect_treehash "**/*"
    assert_output "045920f7394d11e513a8d518bc5d5fb28174c8a2fd32b7e285bc6bca8f8b30ac"
    assert_success

    # We can glob to grab only one ".txt" file
    run collect_treehash "**/*.txt"
    assert_output "7177efbf09c4d1e482cf116ab953f6c59fc706a7fe663695e9e4816dc0e51670"
    assert_success

    # We can glob something that has no files/doesn't exist
    run collect_treehash "**/*.null"
    assert_output "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    assert_success
    run collect_treehash "${dir}/null"
    assert_output "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    assert_success

    # If we change just the filename of something, the treehash changes
    mv "${dir}/A/general_kenobi.txt" "${dir}/A/general_kenobi2.txt"
    run collect_treehash "${dir}"
    assert_output "8d2d84a181b2db6636ca8a6457eb1d2ed603a1012479e73059067f22afb9a4a4"
    assert_success

    # If we change just the content of something, the treehash changes
    echo >> "${dir}/A/general_kenobi2.txt"
    run collect_treehash "${dir}"
    assert_output "c6b819939ed2c9675d08c5d880a78813661f8e05ff9d4e875a576d0612456558"
    assert_success

    popd
}

