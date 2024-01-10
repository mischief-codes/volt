import { loadEnv, defineConfig } from 'vite';
import reactRefresh from '@vitejs/plugin-react';
import { urbitPlugin } from '@urbit/vite-plugin-urbit';

// https://vitejs.dev/config/
export default ({ mode }) => {
  const env = loadEnv(mode, process.cwd());
  return defineConfig({
    define: { 'process.env': env },
    plugins: [urbitPlugin({ base: 'volt', target: env.VITE_SHIP_URL, secure: false }), reactRefresh()]
  });
};
