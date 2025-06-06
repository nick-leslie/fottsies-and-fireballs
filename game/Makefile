run: game
	./game

gleam: game
	gleam build

game: gleam
	bun build ./build/dev/javascript/game/gleam.main.mjs --compile --outfile game

prod-windows: gleam
	bun build ./build/dev/javascript/game/gleam.main.mjs --compile --target=bun-windows-x64-baseline  --minify --sourcemap game

prod-linux: gleam
	bun build ./build/dev/javascript/game/gleam.main.mjs --compile --target=bun-linux-x64-baseline  --minify --sourcemap --outfile game.prod
