import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  server: {
    allowedHosts: [
      "localhost",
      "127.0.0.1",
      "::1",
      "hanback.arorms.cn"
    ]
  },
  plugins: [react()],
})
