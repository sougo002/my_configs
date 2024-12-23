use std::env;
use std::fs;
use std::io::{self, BufRead};
use std::path::{Path, PathBuf};
use std::process::Command;

#[cfg(target_os = "windows")]
fn get_dir_name() -> Result<String, io::Error> {
    // TODO: Windowsの動作チェックする
    let username = std::env::var("USERNAME").unwrap_or_else(|_| "unknown".to_string());
    let startup_path = format!(
        r"C:\Users\{}\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup",
        username
    );
    Ok(startup_path)
}

#[cfg(target_os = "linux")]
fn get_dir_name() -> Result<PathBuf, io::Error> {
    // TODO: linuxの動作チェックする
    // WSL2からWindowsのユーザ名を取得
    let output = Command::new("cmd.exe")
        .args(&["/C", "echo %USERNAME%"])
        .output()?;
    let username = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let target_dir = PathBuf::from(format!(
        "/mnt/c/Users/{}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup",
        username
    ));
    Ok(target_dir)
}

fn main() -> io::Result<()> {
    // 引数に結合後のファイル名を受け取る(必須)
    // --dir(-d)引数にディレクトリを受け取る(任意)。デフォルトはwinのスタートアップフォルダ
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!(
            "使用法: {} <結合後のファイル名> [--dir <ディレクトリ>]",
            args[0]
        );
        std::process::exit(1);
    }

    let output_file_name = &args[1];
    let mut target_dir = get_dir_name()?;

    let mut i = 2;
    while i < args.len() {
        match args[i].as_str() {
            "--dir" | "-d" => {
                if i + 1 < args.len() {
                    target_dir = PathBuf::from(&args[i + 1]);
                    i += 1;
                } else {
                    eprintln!("--dir オプションにはディレクトリを指定してください。");
                    std::process::exit(1);
                }
            }
            _ => {}
        }
        i += 1;
    }

    // ## 動作
    // 親ディレクトリを作成
    fs::create_dir_all(&target_dir)?;

    // autohotkeyディレクトリの中から結合するファイルを対話的に選択
    let ahk_dir = Path::new("autohotkey");
    let mut ahk_files = Vec::new();
    for entry in fs::read_dir(ahk_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("ahk") {
            ahk_files.push(path);
        }
    }

    if ahk_files.is_empty() {
        println!("結合する.ahkファイルがありません。");
        std::process::exit(0);
    }

    println!("結合するファイルを選択してください（番号をスペース区切りで入力）：");
    for (i, file) in ahk_files.iter().enumerate() {
        println!("{}: {}", i, file.display());
    }

    let stdin = io::stdin();
    let input = stdin.lock().lines().next().unwrap()?;
    let indices: Vec<usize> = input
        .split_whitespace()
        .filter_map(|s| s.parse::<usize>().ok())
        .collect();

    // 選択したファイルを結合
    let mut merged_content = String::new();
    for &index in &indices {
        if let Some(path) = ahk_files.get(index) {
            let content = fs::read_to_string(path)?;
            merged_content.push_str(&content);
            merged_content.push('\n');
        }
    }

    // 結合したファイルを指定ディレクトリにコピー、上書き確認
    let output_path = target_dir.join(output_file_name);
    if output_path.exists() {
        println!(
            "{} は既に存在します。上書きしますか？ (y/n)",
            output_path.display()
        );
        let input = stdin.lock().lines().next().unwrap()?;
        if input.to_lowercase() != "y" || input.to_lowercase() != "yes" {
            println!("処理を中止します。");
            std::process::exit(0);
        }
    }

    fs::write(&output_path, merged_content)?;

    println!(
        "結合したファイルを {} にコピーしました。",
        target_dir.join(output_file_name).display()
    );

    Ok(())
}
