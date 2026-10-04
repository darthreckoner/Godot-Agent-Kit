# Game map

Generated from declarations. Change the source resource and regenerate this map.

## Controls

- **kit_inspector** — Ask your game why. Group: Kit. Keys: F1. [addons/agent_kit/controls/kit.tres](addons/agent_kit/controls/kit.tres)
- **kit_tuning** — Open tuning and controls. Group: Kit. Keys: F2. [addons/agent_kit/controls/kit.tres](addons/agent_kit/controls/kit.tres)
- **kit_finish_effect** — Finish current effect. Group: Kit. Keys: F3. [addons/agent_kit/controls/kit.tres](addons/agent_kit/controls/kit.tres)
- **fly_forward** — Fly forward. Group: Flight. Keys: W. [game/data/controls.tres](game/data/controls.tres)
- **fly_back** — Fly back. Group: Flight. Keys: S. [game/data/controls.tres](game/data/controls.tres)
- **fly_left** — Fly left. Group: Flight. Keys: A. [game/data/controls.tres](game/data/controls.tres)
- **fly_right** — Fly right. Group: Flight. Keys: D. [game/data/controls.tres](game/data/controls.tres)
- **fly_up** — Fly up. Group: Flight. Keys: E. [game/data/controls.tres](game/data/controls.tres)
- **fly_down** — Fly down. Group: Flight. Keys: Q. [game/data/controls.tres](game/data/controls.tres)
- **select_target** — Select and face a rock. Group: Camera and targeting. Keys: Left mouse. [game/data/controls.tres](game/data/controls.tres)
- **orbit_camera** — Orbit camera (hold and drag). Group: Camera and targeting. Keys: Right mouse. [game/data/controls.tres](game/data/controls.tres)
- **zoom_in** — Zoom in. Group: Camera and targeting. Keys: Wheel up. [game/data/controls.tres](game/data/controls.tres)
- **zoom_out** — Zoom out. Group: Camera and targeting. Keys: Wheel down. [game/data/controls.tres](game/data/controls.tres)
- **drill** — Drill selected target. Group: Mining and dock. Keys: Space. [game/data/controls.tres](game/data/controls.tres)
- **sell_and_refuel** — Sell and refuel. Group: Mining and dock. Keys: Enter / Numpad Enter. [game/data/controls.tres](game/data/controls.tres)
- **hit_look** — Switch hit look (same damage). Group: Trials and session. Keys: B. [game/data/controls.tres](game/data/controls.tres)
- **charge_policy** — Switch charge policy. Group: Trials and session. Keys: V. [game/data/controls.tres](game/data/controls.tres)
- **save** — Save. Group: Trials and session. Keys: F5. [game/data/controls.tres](game/data/controls.tres)
- **load** — Load. Group: Trials and session. Keys: F9. [game/data/controls.tres](game/data/controls.tres)
- **restart** — Restart trials. Group: Trials and session. Keys: R. [game/data/controls.tres](game/data/controls.tres)
- **exit** — Exit. Group: Trials and session. Keys: Escape. [game/data/controls.tres](game/data/controls.tres)

## Actions

- **mine** — Hit a selected rock; pay energy and collect ore on break. [game/data/mine.tres](game/data/mine.tres)
  - Requires: mining.in_range: Fly closer: the drill must reach the rock.; mining.cooldown: Wait for the mining tool cooldown.; mining.energy: There must be enough energy for this hit.
  - Charge: tuning/mining.charge_on_attempt (0: ON_SUCCESS; 1: ON_ATTEMPT); overflow: CLIP; tuning: mining; success events: mine_hit; rejection events: mine_rejected; clip events: cargo_clipped.
- **move_ship** — Move the ship using fixed-tick acceleration and braking. [game/data/move_ship.tres](game/data/move_ship.tres)
  - Requires: handler checks
  - Charge: ON_SUCCESS; overflow: REJECT; tuning: ship; success events: ship_moved; rejection events: dock_rejected; clip events: .
- **sell_and_refuel** — Sell all ore and buy a full energy refill at the dock. [game/data/sell_and_refuel.tres](game/data/sell_and_refuel.tres)
  - Requires: economy.at_dock: Move within the dock's trading range.
  - Charge: ON_SUCCESS; overflow: REJECT; tuning: economy; success events: dock_success; rejection events: dock_rejected; clip events: .

## Events

- **target_selected** — The view selected a target; no rule action or world change occurred. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)
- **mine_hit** — The tool contacted a rock. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)
- **rock_break** — A rock broke and yielded ore. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)
- **mine_rejected** — A mining check failed. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)
- **cargo_clipped** — Cargo filled and excess ore was clipped. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)
- **ship_moved** — Flight input changed position or velocity. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)
- **dock_success** — Cargo was sold and energy refilled. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)
- **dock_rejected** — Docking or refuelling requirements failed. Payload: entity, actor, action. [game/data/events.tres](game/data/events.tres)

## Tuning

- **kit** — Clock and evidence limits. [addons/agent_kit/tuning/system.tres](addons/agent_kit/tuning/system.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | tick_rate | 30.0 | Hz | 1.0 to 120.0 | Simulation ticks each second. Restart needed. |
  | log_capacity | 512 | records | 32.0 to 8192.0 | Recent operations and events kept during play. |
  | flash_decay | 2.5 | opacity/s | 0.1 to 20.0 | How quickly the screen flash fades; no rule effects. |

- **feel_cargo_clipped_0** — Cargo full warning presentation. [game/feel/stages/cargo_clipped_0.tres](game/feel/stages/cargo_clipped_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.18 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.02 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.08 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_dock_rejected_0** — Dock unavailable presentation. [game/feel/stages/dock_rejected_0.tres](game/feel/stages/dock_rejected_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.14 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.02 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_dock_success_0** — Trade complete presentation. [game/feel/stages/dock_success_0.tres](game/feel/stages/dock_success_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.25 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.015 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.1 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_0** — Windup presentation. [game/feel/stages/mine_hit_0.tres](game/feel/stages/mine_hit_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.05 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.0 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_1** — Contact presentation. [game/feel/stages/mine_hit_1.tres](game/feel/stages/mine_hit_1.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.04 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.0 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_2** — Impact presentation. [game/feel/stages/mine_hit_2.tres](game/feel/stages/mine_hit_2.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.16 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.04 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.1 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.1 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_3** — Debris presentation. [game/feel/stages/mine_hit_3.tres](game/feel/stages/mine_hit_3.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.22 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.0 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_heavy_0** — Windup presentation. [game/feel/stages/mine_hit_heavy_0.tres](game/feel/stages/mine_hit_heavy_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.16 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.0 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_heavy_1** — Contact presentation. [game/feel/stages/mine_hit_heavy_1.tres](game/feel/stages/mine_hit_heavy_1.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.08 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.05 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_heavy_2** — Heavy impact presentation. [game/feel/stages/mine_hit_heavy_2.tres](game/feel/stages/mine_hit_heavy_2.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.35 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.09 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.35 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.25 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_hit_heavy_3** — Debris presentation. [game/feel/stages/mine_hit_heavy_3.tres](game/feel/stages/mine_hit_heavy_3.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.35 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.08 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_mine_rejected_0** — Dull clunk presentation. [game/feel/stages/mine_rejected_0.tres](game/feel/stages/mine_rejected_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.12 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.035 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_rock_break_0** — Fracture presentation. [game/feel/stages/rock_break_0.tres](game/feel/stages/rock_break_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.18 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.2 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.16 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_rock_break_1** — Debris presentation. [game/feel/stages/rock_break_1.tres](game/feel/stages/rock_break_1.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 2.5 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.0 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_ship_moved_0** — Thrusters presentation. [game/feel/stages/ship_moved_0.tres](game/feel/stages/ship_moved_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.033333 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.0 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **feel_target_selected_0** — Immediate target acknowledgement; the nose turn is presentation only. [game/feel/stages/target_selected_0.tres](game/feel/stages/target_selected_0.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | duration | 0.12 | s | 0.0 to 5.0 | Presentation time for this stage; never changes rule time. |
  | sound_marker_sec | 0.0 | s | 0.0 to 5.0 | Time in the sound where the stage makes contact. |
  | shake_amplitude | 0.0 | strength | 0.0 to 2.0 | Strength sent to the game's presentation camera. |
  | shake_frequency | 20.0 | Hz | 0.0 to 80.0 | Shake oscillations per second. |
  | screen_flash | 0.0 | opacity | 0.0 to 1.0 | Brightness of the brief screen flash. |

- **economy** — Dock trade and energy prices. [game/tuning/economy.tres](game/tuning/economy.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | iron_price | 5.0 | credits/ore | 0.0 to 50.0 | Credits received for one unit of iron. |
  | gold_price | 12.0 | credits/ore | 0.0 to 50.0 | Credits received for one unit of gold. |
  | stone_price | 2.0 | credits/ore | 0.0 to 50.0 | Credits received for one unit of stone. |
  | refuel_price | 0.5 | credits/energy | 0.0 to 10.0 | Credits paid for each unit of energy refilled. |
  | dock_range | 3.0 | m | 1.0 to 10.0 | Distance from the dock needed to sell and refuel. |

- **mining** — Mining rules and charge policy. [game/tuning/mining.charge_on_attempt.tres](game/tuning/mining.charge_on_attempt.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | energy_cost | 4.0 | energy | 0.0 to 20.0 | Energy paid for each successful mining hit. |
  | range | 2.5 | m | 1.0 to 30.0 | Reach from the ship's centre to the rock's centre. About 2 m puts the drill against the rock face. |
  | cooldown | 0.3 | s | 0.033333 to 3.0 | Rule time between hits, independent of animation. |
  | tool_power | 2.0 | power | 0.25 to 10.0 | Tool strength compared with the rock's hardness. |
  | iron_yield | 3.0 | ore | 0.0 to 20.0 | Iron collected when an iron rock breaks. |
  | gold_yield | 1.0 | ore | 0.0 to 20.0 | Gold collected when a gold rock breaks. |
  | stone_yield | 2.0 | ore | 0.0 to 20.0 | Stone collected when a stone rock breaks. |
  | soft_threshold | 1.0 | hardness | 0.25 to 10.0 | Hardness of soft rocks. Restart needed. |
  | medium_threshold | 2.0 | hardness | 0.25 to 10.0 | Hardness of medium rocks. Restart needed. |
  | hard_threshold | 4.0 | hardness | 0.25 to 10.0 | Hardness of hard rocks. Restart needed. |
  | rock_health | 4.0 | health | 1.0 to 40.0 | Initial health of each rock block. Restart needed. |
  | charge_on_attempt | 1 | policy | 0.0 to 1.0 | 0: charge successful hits only. 1: also charge attempts against hard rocks. |

- **mining** — Mining rules and charge policy. [game/tuning/mining.tres](game/tuning/mining.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | energy_cost | 4.0 | energy | 0.0 to 20.0 | Energy paid for each successful mining hit. |
  | range | 4.0 | m | 1.0 to 30.0 | Reach from the ship's centre to the rock's centre. About 2 m puts the drill against the rock face. |
  | cooldown | 0.299997 | s | 0.033333 to 3.0 | Rule time between hits, independent of animation. |
  | tool_power | 2.0 | power | 0.25 to 10.0 | Tool strength compared with the rock's hardness. |
  | iron_yield | 3.0 | ore | 0.0 to 20.0 | Iron collected when an iron rock breaks. |
  | gold_yield | 1.0 | ore | 0.0 to 20.0 | Gold collected when a gold rock breaks. |
  | stone_yield | 2.0 | ore | 0.0 to 20.0 | Stone collected when a stone rock breaks. |
  | soft_threshold | 1.0 | hardness | 0.25 to 10.0 | Hardness of soft rocks. Restart needed. |
  | medium_threshold | 2.0 | hardness | 0.25 to 10.0 | Hardness of medium rocks. Restart needed. |
  | hard_threshold | 4.0 | hardness | 0.25 to 10.0 | Hardness of hard rocks. Restart needed. |
  | rock_health | 4.0 | health | 1.0 to 40.0 | Initial health of each rock block. Restart needed. |
  | charge_on_attempt | 0 | policy | 0.0 to 1.0 | 0: charge successful hits only. 1: also charge attempts against hard rocks. |

- **presentation** — Orbit camera and feedback fades; no rule effects. [game/tuning/presentation.tres](game/tuning/presentation.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | camera_distance | 17.0 | m | 8.0 to 35.0 | Initial orbit-camera distance. Restart needed. |
  | camera_fov | 55.0 | degrees | 35.0 to 90.0 | Camera field of view. |
  | orbit_sensitivity | 0.007 | rad/px | 0.001 to 0.03 | Orbit angle per pixel of mouse movement. |
  | zoom_step | 1.0 | m/step | 0.25 to 3.0 | Distance changed by one mouse-wheel step. |
  | camera_min | 8.0 | m | 4.0 to 15.0 | Closest orbit distance. |
  | camera_max | 35.0 | m | 16.0 to 60.0 | Farthest orbit distance. |
  | shake_decay | 1.8 | strength/s | 0.1 to 10.0 | How quickly camera shake fades after an impact. |
  | pulse_decay | 3.0 | strength/s | 0.1 to 10.0 | How quickly the mining tool glow settles. |
  | flight_pulse_decay | 3.0 | strength/s | 0.1 to 10.0 | How quickly the thruster feedback settles after flight input. |
  | toast_duration | 3.0 | s | 0.5 to 10.0 | How long rejection and cargo messages remain visible. |
  | ship_turn_rate | 240.0 | degrees/s | 30.0 to 1080.0 | Top speed of the ship model's turn when W follows the camera or a click faces a rock once. Looks only; flight rules ignore it. |
  | ship_turn_ease | 0.3 | s | 0.05 to 1.5 | Seconds the ship model takes to speed up into a turn and to settle out of it. Higher feels heavier and smoother. |
  | camera_start_yaw | -45.0 | degrees | -180.0 to 180.0 | Starting orbit angle around the ship. -90 sits directly behind the ship, looking past its nose at the rocks; 0 looks at its side. Restart needed. |

- **ship** — Flight and ship capacities. [game/tuning/ship.tres](game/tuning/ship.tres)

  | Knob | Value | Unit | Range | Help |
  |---|---:|---|---|---|
  | speed | 4.0 | m/s | 0.5 to 20.0 | Maximum flight speed. |
  | accel | 7.0 | m/s² | 0.5 to 30.0 | How quickly the ship responds and brakes. |
  | energy_max | 60.0 | energy | 1.0 to 200.0 | Full energy capacity on the next setup. Restart needed. |
  | cargo_capacity | 12.0 | ore | 1.0 to 100.0 | Shared capacity of all ore types on the next setup. Restart needed. |
  | starting_credits | 20.0 | credits | 0.0 to 1000.0 | Credits at the start of a run. Restart needed. |


## Record types

- **dock** — A trading and refuelling location. Fields: {"position":"array"}. Limits: {}. [game/data/dock_type.tres](game/data/dock_type.tres)
- **rock** — An asteroid block with hardness, health and ore. Fields: {"hardness":"float","health":"float","ore_amount":"float","ore_type":"string","position":"array"}. Limits: {"hardness":{"min":0},"health":{"min":0},"ore_amount":{"min":0}}. [game/data/rock_type.tres](game/data/rock_type.tres)
- **ship** — The player's authoritative ship. Fields: {"cargo":"dictionary","cargo_capacity":"float","credits":"float","energy":"float","energy_max":"float","mine_ready_at":"float","position":"array","velocity":"array"}. Limits: {"cargo":{"aggregate":true,"max_field":"cargo_capacity","min":0},"cargo_capacity":{"min":1},"credits":{"min":0},"energy":{"max_field":"energy_max","min":0},"energy_max":{"min":1},"mine_ready_at":{"min":0}}. [game/data/ship_type.tres](game/data/ship_type.tres)

## Feel sequences

- **cargo_clipped** — cargo clipped Event: cargo_clipped; stages: Cargo full warning (0.18s). [game/feel/cargo_clipped.tres](game/feel/cargo_clipped.tres)
- **dock_rejected** — dock rejected Event: dock_rejected; stages: Dock unavailable (0.14s). [game/feel/dock_rejected.tres](game/feel/dock_rejected.tres)
- **dock_success** — dock success Event: dock_success; stages: Trade complete (0.25s). [game/feel/dock_success.tres](game/feel/dock_success.tres)
- **mine_hit** — Light hit look — same damage Event: mine_hit; stages: Windup (0.05s) → Contact (0.04s) → Impact (0.16s) → Debris (0.22s). [game/feel/mine_hit.tres](game/feel/mine_hit.tres)
- **mine_hit_heavy** — Heavy hit look — same damage Event: mine_hit; stages: Windup (0.16s) → Contact (0.08s) → Heavy impact (0.35s) → Debris (0.35s). [game/feel/mine_hit_heavy.tres](game/feel/mine_hit_heavy.tres)
- **mine_rejected** — mine rejected Event: mine_rejected; stages: Dull clunk (0.12s). [game/feel/mine_rejected.tres](game/feel/mine_rejected.tres)
- **rock_break** — rock break Event: rock_break; stages: Fracture (0.18s) → Debris (2.5s). [game/feel/rock_break.tres](game/feel/rock_break.tres)
- **ship_moved** — ship moved Event: ship_moved; stages: Thrusters (0.033333s). [game/feel/ship_moved.tres](game/feel/ship_moved.tres)
- **target_selected** — Target selected Event: target_selected; stages: Ready to drill (0.12s). [game/feel/target_selected.tres](game/feel/target_selected.tres)

## Scenarios

- **charge_policy_binding** — A bound charge policy follows live tuning through queueing, Discard and legacy save restoration. [scenarios/charge_policy_binding.gd](scenarios/charge_policy_binding.gd)
- **economy_round_trip** — Mine, fly to the dock, sell ore and buy a full refill. [scenarios/economy_round_trip.gd](scenarios/economy_round_trip.gd)
- **feel_change_is_scoped** — Compare light and heavy impacts while preserving every mining outcome and tick. [scenarios/feel_change_is_scoped.gd](scenarios/feel_change_is_scoped.gd)
- **kit_integrity** — Verify atomicity, RNG auditing, queue order, tuning trials, save recovery and migration. [scenarios/kit_integrity.gd](scenarios/kit_integrity.gd)
- **large_terrain_records** — Measure action staging with 2,000 large terrain records; only two touched records may be copied. [scenarios/large_terrain_records.gd](scenarios/large_terrain_records.gd)
- **mine_basic** — Mine a soft rock and verify energy and ore accounting. [scenarios/mine_basic.gd](scenarios/mine_basic.gd)
- **mine_full_cargo** — Clip new ore at shared capacity without removing existing cargo. [scenarios/mine_full_cargo.gd](scenarios/mine_full_cargo.gd)
- **mine_hard_rock** — Prove success-only rejection and paid zero-yield attempts. [scenarios/mine_hard_rock.gd](scenarios/mine_hard_rock.gd)
- **mine_out_of_range** — A rock out of drill reach rejects without cost; flying in and stopping makes it minable. [scenarios/mine_out_of_range.gd](scenarios/mine_out_of_range.gd)
- **play_controls** — Rebind through F2; new keys fly, old keys stop, conflicts refuse, Discard/reset restore, and Apply persists project defaults. [scenarios/play_controls.gd](scenarios/play_controls.gd)
- **play_flight_and_dock** — Drive camera orbit and WASD through physical input; Numpad Enter and Enter both trade at the dock. [scenarios/play_flight_and_dock.gd](scenarios/play_flight_and_dock.gd)
- **play_overlay_defaults** — Inspect every default F1 tab and empty-search F2 before filling panels; explain an input-driven refusal. [scenarios/play_overlay_defaults.gd](scenarios/play_overlay_defaults.gd)
- **play_targeting** — Physical clicks select and face once; Space alone drills, clears broken targets and explains hard gold. [scenarios/play_targeting.gd](scenarios/play_targeting.gd)
- **rng_two_streams** — Audit two rule RNG streams in alphabetical order, even when drawn in reverse order. [scenarios/rng_two_streams.gd](scenarios/rng_two_streams.gd)
- **scenario_tuning_pins** — Scenario pins validate together, preserve resources and files, and establish the Discard baseline. [scenarios/scenario_tuning_pins.gd](scenarios/scenario_tuning_pins.gd)
- **shipped_default_balance** — Report changes to shipped mining, ship and economy defaults separately from rule fixtures. [scenarios/shipped_default_balance.gd](scenarios/shipped_default_balance.gd)
