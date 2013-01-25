p = GauntletOfFools::Player.new('Tester', GauntletOfFools::Hero['Alchemist'], GauntletOfFools::Weapon['Sack of Loot'], [])
e = GauntletOfFools::Encounter['Gargoyle']
GauntletOfFools::EncounterPhase.test_encounter(e).run(p)
