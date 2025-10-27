import axios from 'axios'

const API_BASE_URL = `${import.meta.env.VITE_API_URL || window.location.origin}/api`

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    // Let browser set Content-Type for FormData
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    }

    return config
  },
  (error) => Promise.reject(error)
)

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid, clear auth data
      localStorage.removeItem('auth_token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    console.error('API Error:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

export default api
