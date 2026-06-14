#[derive(Copy, Clone)]
pub struct Args <'a> {
    pub help: bool,
    pub version: bool,
    pub inject: bool,
    pub compress: bool,
    pub auto: bool,
    pub decompile: bool,
    pub uninstall: bool,
    pub linux_native: bool,
    pub balatro_path: Option<&'a str>,
    pub balatro_version: Option<&'a str>,
    pub input: Option<&'a str>,
    pub output: Option<&'a str>,
}

impl Default for Args<'_> {
    fn default() -> Self {
        Self { 
            help: false,
            version: false,
            inject: false, 
            compress: false, 
            auto: false, 
            decompile: false, 
            uninstall: false, 
            linux_native: false, 
            balatro_path: None, 
            balatro_version: None, 
            input: None, 
            output: None, 
        }
    }
}

fn is_parametric(str: &str) -> bool {
    match str {
        "-b" | "--balatro-path" | "-v" | "--balatro-version" | "-i" | "--input" | "-o" | "--output" 
            => true,
        _ => false,
    }
}

pub fn split_args<'a>(args: &'a Vec<String>) -> Vec<Vec<&'a String>> {
    let mut iter = args.iter();
    let mut res = Vec::new();
    while let Some(arg) = iter.next() {
        let mut vec = Vec::from([arg]);
        if is_parametric(arg) { vec.push(iter.next().unwrap()) }
        res.push(vec);
    }
    res
}

pub fn parse_args<'a>(args: Vec<Vec<&'a String>>) -> Args<'a> {
    let mut res = Args::default();
    for group in args {
        match group.get(0).unwrap().as_str() {
            "a" | "auto" => res.auto = true,
            "c" | "compress" => res.compress = true,
            "d" | "decompile" => res.decompile = true,
            "u" | "uninstall" => res.uninstall = true,
            "x" | "inject" => res.inject = true,
            "--linux-native" => res.linux_native = true,
            "--help" => res.help = true,
            "--version" => res.version = true,
            "-b" | "--balatro-path" => res.balatro_path = group.get(1).map(|v| v.as_str()),
            "-v" | "--balatro-version" => res.balatro_version = group.get(1).map(|v| v.as_str()),
            "-i" | "--input" => res.input = group.get(1).map(|v| v.as_str()),
            "-o" | "--output" => res.output = group.get(1).map(|v| v.as_str()),
            _ => {},
        }
    }    
    return res;
}
