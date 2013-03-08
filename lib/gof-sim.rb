$:<< File.expand_path(File.dirname(__FILE__))
require 'gof-sim/support'

# FIXME: maybe re-work this categorization
require 'gof-sim/objects/game_object'
require 'gof-sim/game_state/decision'

require 'gof-sim/objects/weapon'
require 'gof-sim/objects/brag'
require 'gof-sim/objects/hero'
require 'gof-sim/objects/encounter'

require 'gof-sim/game_state/game'
require 'gof-sim/game_state/player'
require 'gof-sim/game_state/player_state'
require 'gof-sim/game_state/option'

require 'gof-sim/ai/basic-ai'
require 'gof-sim/ai/weight-ai'

# TODO: distinguish between per-turn and per-encounter effects
# TODO: in WeightAI, fork on probabilistic events and apply weights to score
# TODO: Fix WEIGHTS constant in WeightAI