# Volt UI

## Developing
- Run %volt as described in the ``../README.md``
- Run `yarn install` inside `volt/ui`
- Run `vite --mode zod` / `vite --mode wet` to run the UI against the `.env.zod` / `.env.wet` config files respectively

Alternatively, you can make your own config file by setting `VITE_SHIP_URL` and `VITE_SHIP_NAME` (e.g. for `.env.bus `run `vite --mode bus`)

If you run the app in development mode like this, it will not show up in Landscape.

## Building / Installing

 - Run `yarn build` inside your `ui` directory, which will bundle all the code and assets into the `dist` folder
 - Navigate to ${ship_url}/docket/upload (e.g. http://localhost/docket/upload) and upload `dist`

 You should then see a tile for Volt in Landscape. If you `|commit %volt`, the Landscape tile will show an error, and you will need to upload `dist` again.
