// File: supabase/functions/midtrans-webhook/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // 1. SETUP CORS (Biar aman dan bisa diakses)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }})
  }

  try {
    // 2. TERIMA DATA DARI MIDTRANS (Via Webhook)
    const notification = await req.json()
    
    console.log("Notifikasi masuk:", notification)

    const orderId = notification.order_id
    const transactionStatus = notification.transaction_status
    const fraudStatus = notification.fraud_status

    // 3. LOGIKA STATUS TRANSAKSI MIDTRANS
    let finalStatus = 'PENDING'

    if (transactionStatus == 'capture') {
      if (fraudStatus == 'challenge') {
        finalStatus = 'CHALLENGE'
      } else if (fraudStatus == 'accept') {
        finalStatus = 'SUCCESS' // <-- LUNAS
      }
    } else if (transactionStatus == 'settlement') {
      finalStatus = 'SUCCESS' // <-- LUNAS
    } else if (transactionStatus == 'cancel' || transactionStatus == 'deny' || transactionStatus == 'expire') {
      finalStatus = 'FAILED'
    } else if (transactionStatus == 'pending') {
      finalStatus = 'PENDING'
    }

    // 4. KONEK KE DATABASE
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 5. UPDATE STATUS DI DATABASE KITA
    // Cari data berdasarkan order_id, lalu ubah statusnya
    const { error } = await supabase
      .from('kas_transactions')
      .update({ status: finalStatus })
      .eq('order_id', orderId)

    if (error) throw error

    console.log(`Sukses update Order ${orderId} jadi ${finalStatus}`)

    // 6. JAWAB 'OK' KE MIDTRANS
    return new Response(JSON.stringify({ message: 'OK' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})