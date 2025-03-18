run: game
	steam-run ./game

gleam:
	steam-run gleam build

game: gleam
	steam-run bun build ./build/dev/javascript/game/gleam.main.mjs --compile --outfile game
