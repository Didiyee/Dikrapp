import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // للتجربة على الهاتف عبر نفس شبكة الواي فاي: npm run dev:phone
  server: { host: true },
  preview: { host: true },
})
