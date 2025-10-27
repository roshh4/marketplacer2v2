import { useState, useRef } from 'react'
import { ArrowLeft, X } from 'lucide-react'
import { useMarketplace } from '../../state/MarketplaceContext'
import { productsAPI } from '../../api/services'
import GlassCard from '../ui/GlassCard'
import Spinner from '../ui/Spinner'
import { Product } from '../../types'

export default function ListItemPage({ onDone }: { onDone: () => void }) {
  const { addProduct, user } = useMarketplace()
  const [title, setTitle] = useState('')
  const [price, setPrice] = useState<number | ''>('')
  const [condition, setCondition] = useState<Product['condition']>('Good')
  const [category, setCategory] = useState('Books')
  const [desc, setDesc] = useState('')
  const [tags, setTags] = useState<string[]>([])
  const [tagInput, setTagInput] = useState('')
  const [images, setImages] = useState<File[]>([])
  const [loading, setLoading] = useState(false)
  const [aiGenerating, setAiGenerating] = useState(false)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  const onDrop = (files: FileList | null) => {
    if (!files) return
    const newImages = Array.from(files).slice(0, 6 - images.length)
    console.log('📁 Files dropped:', newImages.length, newImages.map(f => f.name))
    setImages((s) => {
      const updated = [...s, ...newImages]
      console.log('📁 Updated images state:', updated.length, updated.map(f => f.name))
      return updated
    })
  }

  const removeImg = (i: number) => setImages((s) => s.filter((_, idx) => idx !== i))

  const addTag = () => {
    const t = tagInput.trim()
    if (!t) return setTagInput('')
    if (!tags.includes(t)) setTags((s) => [t, ...s])
    setTagInput('')
  }

  const generateDesc = async () => {
    if (!title.trim()) {
      alert('Please enter a title first to generate a description')
      return
    }

    setAiGenerating(true)
    try {
      console.log('🤖 Generating AI description...')
      console.log('Title:', title)
      console.log('Category:', category)
      console.log('Images:', images.length)

      // Create FormData with files
      const formData = new FormData()
      formData.append('title', title.trim())
      formData.append('category', category)
      
      // Debug: Log images array
      console.log('🔍 Images to upload:', images.length, images)
      
      // Add image files
      images.forEach((image, index) => {
        console.log(`📎 Adding image ${index}:`, image.name, image.size, 'bytes')
        formData.append('images', image)
      })

      // Debug: Log FormData contents
      console.log('📋 FormData contents:')
      for (let [key, value] of formData.entries()) {
        console.log(`  ${key}:`, value instanceof File ? `${value.name} (${value.size} bytes)` : value)
      }

      console.log('🌐 Calling API endpoint: /api/products/generate-description-with-files')
      const response = await productsAPI.generateDescriptionWithFiles(formData)

      console.log('✨ AI Response:', response.data)
      
      if (response.data.success) {
        setDesc(response.data.description)
        alert(`✨ Description generated successfully using ${response.data.model_used}!\n\nProcessing time: ${response.data.processing_time}`)
      } else {
        throw new Error(response.data.error || 'Failed to generate description')
      }
    } catch (error: any) {
      console.error('❌ AI generation failed:', error)
      
      // Fallback to a simple template
      const fallbackDesc = `Quality ${title} in good condition, perfect for students looking for great value and reliable performance.`
      setDesc(fallbackDesc)
      
      alert(`⚠️ AI generation failed, using template description instead.\n\nError: ${error.response?.data?.error || error.message}`)
    } finally {
      setAiGenerating(false)
    }
  }

  const submit = async () => {
    if (!title || !isFinite(price as number) || (price as number) < 0 || images.length === 0) return alert('Please enter a valid title, a non-negative price, and at least one image')

    console.log('--- Submitting product ---');
    console.log('Title:', title);
    console.log('Price:', price);
    console.log('Description:', desc);
    console.log('Condition:', condition);
    console.log('Category:', category);
    console.log('Tags:', tags);
    console.log('Images:', images);
    console.log('--------------------------');

    setLoading(true)
    await new Promise((r) => setTimeout(r, 800))
    addProduct({
      title,
      price: price as number,
      description: desc,
      images,
      condition,
      category,
      tags,
      sellerId: user?.id || 'seller_demo',
      status: 'available',
    })
    setLoading(false)
    onDone()
  }

  return (
    <div className="min-h-screen py-8">
      <div className="max-w-4xl mx-auto px-4 md:px-8">
        <div className="flex items-center gap-4 mb-6">
          <button onClick={onDone} className="p-2 rounded-full bg-white/6">
            <ArrowLeft />
          </button>
          <h2 className="text-2xl font-bold">List New Item</h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="md:col-span-2 space-y-4">
            <GlassCard>
              <div>
                <label className="block text-sm font-semibold">Images</label>
                <div
                  onDragOver={(e) => e.preventDefault()}
                  onDrop={(e) => { e.preventDefault(); onDrop(e.dataTransfer.files) }}
                  className="mt-2 border-dashed border-2 border-white/6 rounded-md p-4 text-center cursor-pointer"
                  onClick={() => fileInputRef.current?.click()}
                >
                  <input ref={fileInputRef} type="file" multiple accept="image/*" onChange={(e) => onDrop(e.target.files)} className="hidden" />
                  <div className="text-sm opacity-70">Drag & drop or click to upload (max 6)</div>
                  <div className="mt-3 grid grid-cols-4 gap-2">
                    {images.map((img, i) => (
                      <div key={i} className="relative">
                        <img src={URL.createObjectURL(img)} className="h-24 w-full object-cover rounded-md" />
                        <button onClick={(e) => { e.stopPropagation(); removeImg(i) }} className="absolute top-1 right-1 p-1 bg-red-500 hover:bg-red-600 text-white rounded-full shadow-lg transition-colors duration-200 z-10">
                          <X size={12} />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </GlassCard>

            <GlassCard>
              <label className="block text-sm font-semibold">Title</label>
              <input value={title} onChange={(e) => setTitle(e.target.value)} className="w-full mt-2 p-2 bg-transparent border rounded-md" />

              <div className="mt-3 grid grid-cols-2 gap-3">
                <div>
                  <label className="text-sm font-semibold">Price (₹)</label>
                  <input type="number" value={price} onChange={(e) => setPrice(e.target.value === '' ? '' : Number(e.target.value))} className="w-full mt-2 p-2 bg-transparent border rounded-md" />
                </div>
                <div>
                  <label className="text-sm font-semibold">Condition</label>
                  <select value={condition} onChange={(e) => setCondition(e.target.value as Product['condition'])} className="w-full mt-2 p-2 bg-transparent border rounded-md">
                    <option>New</option>
                    <option>Like New</option>
                    <option>Good</option>
                    <option>Fair</option>
                    <option>For Parts</option>
                  </select>
                </div>
              </div>

              <div className="mt-3">
                <label className="text-sm font-semibold">Category</label>
                <input value={category} onChange={(e) => setCategory(e.target.value)} className="w-full mt-2 p-2 bg-transparent border rounded-md" />
              </div>

              <div className="mt-3">
                <label className="text-sm font-semibold">Description</label>
                <p className="text-xs text-gray-400 mt-1">AI can analyze your images and generate a compelling description</p>
                <div className="mt-2 flex gap-2">
                  <textarea 
                    value={desc} 
                    onChange={(e) => setDesc(e.target.value)} 
                    rows={4} 
                    className="flex-1 p-2 bg-transparent border rounded-md" 
                    placeholder="Enter description or click AI to generate one..."
                  />
                  <button 
                    onClick={generateDesc} 
                    disabled={aiGenerating || !title.trim()}
                    className={`p-3 rounded-md transition-all duration-200 min-w-[60px] flex items-center justify-center ${
                      aiGenerating 
                        ? 'bg-blue-500/20 text-blue-400 cursor-not-allowed' 
                        : !title.trim()
                        ? 'bg-gray-500/20 text-gray-500 cursor-not-allowed'
                        : 'bg-gradient-to-r from-purple-500/20 to-blue-500/20 hover:from-purple-500/30 hover:to-blue-500/30 text-white hover:scale-105'
                    }`}
                    title={
                      !title.trim() 
                        ? "Enter a title first" 
                        : aiGenerating 
                        ? "Generating description..." 
                        : "Generate AI description"
                    }
                  >
                    {aiGenerating ? (
                      <div className="animate-spin rounded-full h-4 w-4 border-2 border-blue-400 border-t-transparent"></div>
                    ) : (
                      '✨ AI'
                    )}
                  </button>
                </div>
              </div>

              <div className="mt-3">
                <label className="text-sm font-semibold">Tags</label>
                <div className="mt-2 flex gap-2 items-center">
                  <input value={tagInput} onChange={(e) => setTagInput(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && addTag()} className="p-2 bg-transparent border rounded-md flex-1" placeholder="press enter to add" />
                  <button onClick={addTag} className="py-2 px-3 rounded-md bg-white/6">Add</button>
                </div>
                <div className="mt-2 flex gap-2 flex-wrap">
                  {tags.map((t, i) => (
                    <div key={i} className="px-3 py-1 bg-white/6 rounded-full flex items-center gap-2 text-sm">
                      {t} <button onClick={() => setTags((s) => s.filter((x) => x !== t))} className="p-1">×</button>
                    </div>
                  ))}
                </div>
              </div>

              <div className="mt-4 flex gap-3">
                <button onClick={submit} className="py-2 px-4 rounded-md bg-gradient-to-r from-indigo-500 to-cyan-400 font-semibold">
                  {loading ? <Spinner /> : 'List Item'}
                </button>
                <button onClick={onDone} className="py-2 px-4 rounded-md bg-white/6">Cancel</button>
              </div>
            </GlassCard>
          </div>

          <div className="space-y-4">
            <GlassCard>
              <div className="text-sm font-semibold">Preview</div>
              <div className="mt-2">
                <div className="h-40 rounded-md overflow-hidden bg-black/10 grid place-items-center">
                  {images[0] ? <img src={URL.createObjectURL(images[0])} className="w-full h-full object-cover" /> : <div className="opacity-60">No image yet</div>}
                </div>
                <div className="mt-2 font-semibold">{title || 'Item Title'}</div>
                <div className="text-sm opacity-70">₹{price || '0'}</div>
                <div className="text-xs opacity-60 mt-2">{desc || 'Short description will appear here.'}</div>
              </div>
            </GlassCard>

            <GlassCard>
              <div className="text-sm">Tips</div>
              <ul className="mt-2 text-xs opacity-80">
                <li>• Use clear photos and an accurate price.</li>
                <li>• Mention pickup location in description.</li>
              </ul>
            </GlassCard>
          </div>
        </div>
      </div>
    </div>
  )
}
