use std::env;
use std::fs;
use std::path::{Path, PathBuf};

fn create_parent_dirs(path: &Path) -> std::io::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    Ok(())
}

fn process_directory(current_dir: &Path, target_dir: &Path) -> std::io::Result<()> {
    if let Ok(entries) = fs::read_dir(current_dir) {
        for entry in entries.flatten() {
            let path = entry.path();

            if path.is_dir() {
                // ディレクトリを再帰的に処理
                process_directory(&path, target_dir)?;
            } else if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("json") {
                // 相対パスを計算
                let relative_path = path
                    .strip_prefix(env::current_dir().unwrap())
                    .expect("相対パスの計算に失敗");
                let target_path = target_dir.join(relative_path);

                // 親ディレクトリを作成
                if let Err(e) = create_parent_dirs(&target_path) {
                    eprintln!("ディレクトリの作成に失敗: {}", e);
                    continue;
                }

                // コピーを作成
                match fs::copy(&path, &target_path) {
                    Ok(_) => println!("コピーを作成しました: {:?} -> {:?}", target_path, path),
                    Err(e) => eprintln!("エラー: {:?} コピーを作成に失敗: {}", path, e),
                }
            }
        }
    }
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        eprintln!("使用方法: {} <対象ディレクトリのパス>", args[0]);
        std::process::exit(1);
    }

    let target_dir = PathBuf::from(&args[1]);
    let current_dir = env::current_dir().expect("カレントディレクトリを取得できません");

    if let Err(e) = process_directory(&current_dir, &target_dir) {
        eprintln!("処理中にエラーが発生しました: {}", e);
        std::process::exit(1);
    }
}
