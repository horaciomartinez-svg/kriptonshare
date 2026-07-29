// supabase/functions/billing-sync/index.ts
// Webhook server-to-server de RevenueCat para sincronizar tier y almacenamiento.
// El dispositivo móvil jamás escribe su propio max_storage_bytes.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GIGABYTE = 1073741824;
const WEBHOOK_AUTH = Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? "";

serve(async (req) => {
  // 1. Validar autenticidad del webhook (Authorization header compartido)
  const authHeader = req.headers.get("Authorization") ?? "";
  if (authHeader !== `Bearer ${WEBHOOK_AUTH}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json();
  const event = payload.event;
  if (!event?.app_user_id) {
    return new Response("OK", { status: 200 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const userId = event.app_user_id as string;
  const eventType = event.type as string;
  const productId = event.product_id as string | undefined;
  const addonBytes = (event.purchased_storage_bytes_addon as number) || GIGABYTE;

  const isPremiumEvent = ["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE", "NON_RENEWING_PURCHASE"].includes(eventType);
  const isCancellationEvent = ["EXPIRATION", "REFUND", "CANCELLATION"].includes(eventType);

  if (isPremiumEvent) {
    // Suscripción Premium base = 1 GB. Add-ons acumulan +1 GB cada uno.
    const addonCount = productId?.startsWith("storage_addon") ? 1 : 0;
    const isPremiumSubscription = productId === "kriptonshare_premium_monthly" ||
      productId === "kriptonshare_premium_yearly" ||
      !productId?.startsWith("storage_addon");

    const newTier = isPremiumSubscription ? "premium" : "premium";
    const newMaxStorage = GIGABYTE + addonCount * addonBytes;

    await supabase
      .from("users")
      .update({
        subscription_tier: newTier,
        max_storage_bytes: newMaxStorage,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);
  }

  if (isCancellationEvent) {
    // Revertir a gratuito, conservando datos en modo solo lectura hasta depuración.
    await supabase
      .from("users")
      .update({
        subscription_tier: "free",
        max_storage_bytes: 0,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);
  }

  return new Response("OK", { status: 200 });
});
