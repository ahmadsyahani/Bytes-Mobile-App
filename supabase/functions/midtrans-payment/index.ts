// File: supabase/functions/midtrans-payment/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // 1. SETUP CORS (Biar HP bisa akses)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }})
  }

  try {
    // 2. TERIMA DATA DARI FLUTTER
    const { order_id, gross_amount } = await req.json()

    // 3. AMBIL KUNCI RAHASIA (SERVER KEY)
    // Pastikan kamu udah set secrets di terminal tadi ya!
    const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY') ?? ''
    
    // Encode Server Key ke Base64 (Syarat Midtrans)
    const authString = btoa(serverKey + ':')

    // 4. MINTA LINK BAYAR KE MIDTRANS (SNAP API)
    // Gunakan URL Sandbox
    const midtransUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions'

    const payload = {
      transaction_details: {
        order_id: order_id,
        gross_amount: gross_amount
      },
      credit_card: {
        secure: true
      }
    }

    const response = await fetch(midtransUrl, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': `Basic ${authString}`
      },
      body: JSON.stringify(payload)
    })

    const data = await response.json()

    // Cek kalau ada error dari Midtrans
    if (!response.ok) {
      throw new Error(JSON.stringify(data))
    }

    // 5. BALIKIN DATA (TOKEN & URL) KE FLUTTER
    return new Response(JSON.stringify(data), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*' // Penting buat CORS
      },
      status: 200,
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*' 
      },
      status: 400,
    })
  }
})