require '../lib/gof-sim'

p = GauntletOfFools::Player.new('Tester', GauntletOfFools::Hero['Monk'], [GauntletOfFools::Weapon['Spear']], [])
e = GauntletOfFools::Encounter['Gold Vein']
GauntletOfFools::EncounterPhase.test_encounter(e).run(p)
