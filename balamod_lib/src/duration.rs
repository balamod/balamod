use std::time::Duration;
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
pub struct StepDuration {
    pub duration: Duration,
    pub name: String,
}
