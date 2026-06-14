use textfmt::*;
use smol::{io::AsyncWriteExt, stream::StreamExt};

mod archive;
mod parser;
mod paths;
mod dependencies;

type Error = Box<dyn std::error::Error>;
type SendError = Box<dyn std::error::Error + std::marker::Send>;
const VERSION: &str = env!("CARGO_PKG_VERSION");
const BIN_NAME: &'static str = env!("CARGO_BIN_NAME");
fn print_help_info() {
    let balatro = "Balatro".cyan().italic();
    println!("{} is a {}, {}, and {} for {balatro} that supports in-game code injection.",
        BIN_NAME.red().italic(),
        "mod loader".blue(),
        "injector".blue(),
        "decompiler".blue());
    println!();
    println!("{}{}", "Usage".yellow(), ":");
    println!("    {} {} {}", 
        BIN_NAME.yellow(), 
        "a".blue(), 
        "[OPTIONS]".red());
    println!("        Auto-injects the modloader into your {balatro} install.");
    println!("    {} {} {} {} {} {} {}", 
        BIN_NAME.yellow(), 
        "x".blue(), 
        "-i/--input".red(), 
        "<FILE>".green(),
        "-o/--output".red(), 
        "<FILE>".green(),
        "[OPTIONS]".red());
    println!("        Injects a specific {} file into your {balatro} install.", 
        "input".red());
    println!("        The file is injected into the game at the relative {} location.",
        "output".red());
    println!("    {} {} {}",
        BIN_NAME.yellow(),
        "d".blue(),
        "[OPTIONS]".red());
    println!("        Decompile/extract the {balatro} game files, optionally to a given {} location.",
        "output".red());
    println!();
    println!("{}{}", "Options".yellow(), ":");
    println!("    {}", "--help".red());
    println!("        Display this message.");
    println!("    {}", "--version".red());
    println!("        Display the {} version.", BIN_NAME.red().italic());
    println!("    {}, {} {}", "-i".red(), "--input".red(), "<FILE>".green());
    println!("        Specify an {} file to inject into {balatro}.", "input".red());
    println!("    {}, {} {}", "-o".red(), "--output".red(), "<FILE>".green());
    println!("        Specify where to decompile {balatro} files to, or");
    println!("        where to place files within {balatro} when injecting them.");
    println!("    {}, {} {}", "-b".red(), "--balatro-path".red(), "<PATH>".green());
    println!("        Specify a path to look for {balatro} installations.");
    println!("    {}, {} {}", "-v".red(), "--balatro-version".red(), "<VERSION>".green());
    println!("        Specify a particular {balatro} version to modify.");
    println!("    {}", "--linux-native".red());
    println!("        Specify that {balatro} is running natively on Linux {}.",
        "(not through Proton)".italic().faint());
}

struct Timer { duration: std::time::Duration, name: &'static str }
struct Timers(Vec<Timer>);

impl Timers {
    pub fn init() -> Self { Self(Vec::new()) }
    pub fn add(&mut self, elapsed: &std::time::Instant, name: &'static str) -> &mut Self {
        self.0.push(Timer { duration: elapsed.elapsed(), name });
        return self;
    }
    pub fn inner<'a>(&'a self) -> &'a Vec<Timer> { &self.0 }
}

fn main() -> Result<(), Error> {
    let arg_vec = std::env::args()
        .skip(1)
        .collect();
    let args = parser::parse_args(parser::split_args(&arg_vec));
    let mut durations: Timers = Timers::init();
    if cfg!(target_os = "windows") { enable_ansi_support::enable_ansi_support()?; }
    if args.help { return Ok(print_help_info()) }
    if args.version { return Ok(println!("balamod v{}", VERSION)) }

    if args.inject && args.auto {
        "You can't use inject/x and auto/a at the same time!"
            .bg_red()
            .bright_white()
            .underline()
            .eprintln();
        return Ok(());
    }

    if args.inject && args.decompile {
        "You can't use inject/x and decompile/d at the same time!"
            .bg_red()
            .bright_white()
            .underline()
            .eprintln();
        return Ok(());
    }

    if args.auto && args.decompile {
        "You can't use auto/a and decompile/d at the same time!"
            .bg_red()
            .bright_white()
            .underline()
            .eprintln();
        return Ok(());
    }

    let balatros = paths::get_balatro_paths();
    println!("{}{}{}", 
        "Found "
            .blue(), 
        balatros.len()
            .to_string()
            .blue()
            .bold()
            .underline(),
        " Balatro installations."
            .blue());

    let balatro_path = match args.balatro_path {
        Some(path) => std::path::Path::new(path),
        None => dependencies::get_balatro_path(args.balatro_path, &balatros)?,
    };

    let save_dir = paths::get_save_dir(args.linux_native);
    if !save_dir.exists() { panic!("OS Unsupported!") }

    let global_start = std::time::Instant::now();
    if args.uninstall { uninstall(&save_dir, &mut durations, args.linux_native); }
    if args.inject { inject(args.clone(), balatro_path, &mut durations)?; }
    if args.decompile { extract_game_files(balatro_path, args.output, &mut durations); }
    if args.auto { install(&save_dir, args.balatro_version, &mut durations, args.linux_native)?; }

    format!("Total time: {:?}", global_start.elapsed())
        .red()
        .println();
    for duration in durations.inner() {
        format!("{}: {:?}", duration.name, duration.duration)
            .red()
            .println();
    }
    return Ok(());
}

#[cfg(not(all(target_os = "macos", not(any(target_arch = "aarch64", target_arch = "arm")))))]
fn install(
    save_dir: &std::path::Path,
    version: Option<&str>, 
    durations: &mut Timers, 
    linux_native: bool
) 
    -> Result<(), Error>
{
    Ok(smol::block_on(async {
        if check_version(version, linux_native).await.is_err() { return Ok(()) }
        let lua_ft = dependencies::download_file(dependencies::MAIN_PATCH);
        let balamod_url = dependencies::get_tar_url(version, linux_native);
        let balalib_url = dependencies::get_balalib_url(version, linux_native);
        let balamod_ft = dependencies::download_file(&balamod_url);
        let balalib_ft = dependencies::download_file(&balalib_url);
        if save_dir.join("main.lua").exists() {
            "main.lua already exists, skipping modloader installation...".yellow().println();
            "To reinstall the modloader, please uninstall it first with -u".yellow().println();
            return Ok(());
        }
        let start = std::time::Instant::now();
        for res in easy_parallel::Parallel::new()
            .add(|| smol::future::block_on(install::patch_lua_file(lua_ft, &save_dir)))
            .add(|| smol::future::block_on(install::patch_balamod(balamod_ft, &save_dir, linux_native)))
            .add(|| smol::future::block_on(install::patch_balalib(balalib_ft, &save_dir, linux_native)))
            .run() 
        {
            match res {
                Ok(timers) => for timer in timers.0 { durations.0.push(timer) },
                Err(_) => return Err("Error downloading and patching Balamod"),
            }
        }
        durations.add(&start, "Modloader installation");
        "Done!"
            .green()
            .bold()
            .println();
        return Ok(());
    })?)
}

#[cfg(all(target_os = "macos", not(any(target_arch = "aarch64", target_arch = "arm"))))]
fn install(
    _save_dir: &std::path::Path,
    _version: Option<&str>, 
    _durations: &mut Timers, 
    _linux_native: bool
) 
    -> Result<(), Error>
{
    Ok("Architecture is not supported, skipping modloader injection..."
        .bg_red()
        .bright_white()
        .underline()
        .eprintln())
}

async fn check_version(version: Option<&str>, linux_native: bool) -> Result<(), Error> {
    if let Some(version) = version {
        let version_str = format!("v{}", version);
        format!("Installing Balamod {}...", version_str)
            .cyan()
            .italic()
            .println();
        if !dependencies::balamod_version_exists(&version, linux_native).await {
            (version_str + "does not exist!")
                .bg_red()
                .bright_white()
                .underline()
                .eprintln();
            return Err("Version does not exist".into());
        }
    } else {
        "Installing latest Balamod..."
            .cyan()
            .italic()
            .println();
    }
    return Ok(());
}

fn uninstall(save_dir: &std::path::Path, durations: &mut Timers, linux_native: bool) {
    "Uninstalling Balamod..."
        .cyan()
        .italic()
        .println();
    let start = std::time::Instant::now();
    "Removing `main.lua`..."
        .bright_black()
        .italic()
        .println();
    remove_file_if_exists(&save_dir.join("main.lua"));
    "Removing modloader..."
        .bright_black()
        .italic()
        .println();
    remove_dir_if_exists(&save_dir.join("balamod"));
    "Removing Balalib..."
        .bright_black()
        .italic()
        .println();
    remove_file_if_exists(&save_dir.join(dependencies::get_balalib_name(linux_native)));
    durations.add(&start, "Uninstall Balamod");
    "Done!"
        .green()
        .bold()
        .println();
}
fn remove_file_if_exists(path: &std::path::Path) { if path.exists() { std::fs::remove_file(path).unwrap() } }
fn remove_dir_if_exists(path: &std::path::Path) { if path.exists() { std::fs::remove_dir_all(path).unwrap() } }

fn inject(mut args: parser::Args, path: &std::path::Path, durations: &mut Timers) 
    -> Result<(), Error> 
{
    if args.input.is_none() { args.input = Some("Balatro.lua"); }
    if args.output.is_none() { args.output = Some("DAT1.jkr"); }
    let input = args.input.unwrap();
    let output = args.output.unwrap();
    if !std::path::Path::new(input).exists() { return Ok(()); }

    let mut need_cleanup = None;
    if args.compress {
        let compression_output = std::path::PathBuf::from(
            strip_suffix_if_exists(
                strip_suffix_if_exists(output, ".lua"), 
                ".jkr"
            ).to_string() + ".jkr"
        );

        if compression_output.exists() {
            "Deleting existing file...".yellow().println();
            std::fs::remove_file(&compression_output)?;
        }

        format!("Compressing {} ...", input)
            .bright_black()
            .italic()
            .println();
        let compress_start = std::time::Instant::now();
        archive::zip_utils::compress_file(std::path::Path::new(input), &compression_output)
            .expect("Error while compressing file");
        if !compression_output.to_str().unwrap().eq_ignore_ascii_case(&input) {
            need_cleanup = Some(compression_output);
        }
        durations.add(&compress_start, "Compression");
    }

    let bytes = std::fs::read(
        match &need_cleanup {
            Some(path) => path,
            None => std::path::Path::new(input),
        }
    )?;

    "Injecting..."
        .cyan()
        .italic()
        .println();
    let inject_start = std::time::Instant::now();
    archive::zip_utils::replace_file(path, output, bytes.as_slice())?;
    durations.add(&inject_start, "Injection");
    "Done!"
        .green()
        .bold()
        .println();

    if let Some(path) = need_cleanup {
        "Cleaning up..."
            .cyan()
            .italic()
            .println();
        std::fs::remove_file(path)?;
        "Done!"
            .green()
            .bold()
            .println();
    }
    return Ok(());
}
fn strip_suffix_if_exists<'a>(str: &'a str, suff: &'a str) -> &'a str { str.strip_prefix(suff).unwrap_or(str) }

fn extract_game_files(
    game_path: &std::path::Path,
    output_folder: Option<&str>,
    durations: &mut Timers,
) {
    let output_path = std::path::PathBuf::from(output_folder.unwrap_or("decompiled"));
    if output_path.exists() {
        "Deleting existing output folder..."
            .cyan()
            .italic()
            .println();
        std::fs::remove_dir_all(&output_path).expect("Error while deleting folder");
    }
    "Decompiling..."
        .cyan()
        .italic()
        .println();
    let decompile_start = std::time::Instant::now();
    archive::zip_utils::extract_all(game_path, &output_path).unwrap();
    durations.add(&decompile_start, "Decompilation");
    "Done!"
        .green()
        .bold()
        .println();
}

mod install {
    use super::*;
    pub async fn patch_lua_file
        <T: Future<Output = Result<reqwest::Response, reqwest::Error>>>
        (ft: T, save_dir: &std::path::Path) 
        -> Result<Timers, SendError>
    {
        let mut durations = Timers::init();
        let mut main_lua_file = smol::fs::File::create(save_dir.join("main.lua")).await
            .expect("Error creating `main.lua` file");
        "Downloading and patching main.lua... "
            .bright_black()
            .italic()
            .println();
        let start = std::time::Instant::now();
        let mut stream = ft.await.unwrap().bytes_stream();
        while let Some(chunk_res) = stream.next().await {
            main_lua_file.write_all(&chunk_res.unwrap()).await
                .expect("Error while writing to main.lua");
            }
        main_lua_file.flush().await.unwrap();
        durations.add(&start, "Install `main.lua` patch");
        return Ok(durations);
    }

    pub async fn patch_balamod
        <T: Future<Output = Result<reqwest::Response, reqwest::Error>>>
        (ft: T, save_dir: &std::path::Path, linux_native: bool) 
        -> Result<Timers, SendError>
    {
        let mut durations = Timers::init();
        "Downloading and extracting Balamod... "
            .bright_black()
            .italic()
            .println();
        let start = std::time::Instant::now();
        archive::tar_utils::unpack_tar(
            save_dir.to_str().unwrap(),
            dependencies::finish_download(ft).await.unwrap(),
            linux_native).unwrap();
        durations.add(&start, "Install Balamod files");
        if cfg!(target_os = "linux") && linux_native {
            "Changing http lib..."
                .bright_black()
                .italic()
                .println();
            let start_http = std::time::Instant::now();
            smol::fs::rename(
                save_dir.join("balamod").join("https.so"), 
                save_dir.join("https.so"))
                .await
                .unwrap();
            durations.add(&start_http, "Install HTTP library patch");
        }
        return Ok(durations);
    }

    pub async fn patch_balalib
        <T: Future<Output = Result<reqwest::Response, reqwest::Error>>>
        (ft: T, save_dir: &std::path::Path, linux_native: bool) 
        -> Result<Timers, SendError>
    {
        let mut durations = Timers::init();
        let mut balalib_file = smol::fs::File::create(save_dir.join(dependencies::get_balalib_name(linux_native)))
            .await
            .expect("Error creating `balalib` file");
        "Downloading and installing Balalib... "
            .bright_black()
            .italic()
            .println();
        let install_balalib = std::time::Instant::now();
        let mut stream = ft.await.unwrap().bytes_stream();
        while let Some(chunk_res) = stream.next().await {
            balalib_file.write_all(&chunk_res.unwrap()).await.unwrap();
        }
        balalib_file.flush().await.unwrap();
        durations.add(&install_balalib, "Install Balalib");
        return Ok(durations);
    }
}
