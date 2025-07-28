use std::fs;
use std::path::Path;

fn main() {
    let out_dir = std::env::var("OUT_DIR").unwrap();
    let target_dir = Path::new(&out_dir).parent().unwrap().parent().unwrap().parent().unwrap();

    // Copy jcd_function.sh to target/release (or target/debug)
    let src = "jcd_function.sh";
    let dst = target_dir.join("jcd_function.sh");

    if let Err(e) = fs::copy(src, &dst) {
        println!("cargo:warning=Failed to copy {}: {}", src, e);
    } else {
        println!("cargo:warning=Copied {} to {}", src, dst.display());
    }

    // Tell cargo to rerun this script if jcd_function.sh changes
    println!("cargo:rerun-if-changed=jcd_function.sh");
}