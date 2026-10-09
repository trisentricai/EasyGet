import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  // NEXT_UI vertical-slice preview: /preview.html renders flag-gated components
  // against live data without touching the shipped app's routes.
  build: {
    rollupOptions: {
      input: {
        main: 'index.html',
        preview: 'preview.html',
        privacy: 'privacy.html',
      },
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})