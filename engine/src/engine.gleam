pub type Dir {
  Back
  Forward
  Neutral
  Up
  UpBack
  UpForward
  Down
  DownForward
  DownBackward
}

pub type Attack {
  Light
  Medium
  Heavy
}

pub type Input {
  Input(dir:Dir)
  InputWithAttack(dir:Dir,attack:Attack)
}

