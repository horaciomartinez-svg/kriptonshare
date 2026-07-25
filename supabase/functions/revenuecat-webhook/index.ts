// supabase/functions/revenuecat-webhook/index.ts
// Webhook server-to-server de RevenueCat para actualizar límites de almacenamiento.
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

  const event = await req.json();
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")! // service_role: bypasea RLS
  );

  const userId = event.event?.app_user_id;
  if (!userId) return new Response("OK", { status: 200 });

  // 2. Resolver estado de suscripciones y add-ons activos
  const entitlementIds: string[] = event.event?.entitlement_ids ?? [];

  const isPremium = entitlementIds.includes("premium");
  const addonCount = entitlementIds.filter((e: string) =>
    e.startsWith("storage_addon")
  ).length;

  // 3. Activar / renovar / cambiar producto: actualizar tier y límite
  if (["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE", "NON_RENEWING_PURCHASE"]
      .includes(event.event?.type)) {
    await supabase
      .from("users")
      .update({
        subscription_tier: isPremium ? "premium" : "free",
        max_storage_bytes: isPremium
          ? GIGABYTE + addonCount * GIGABYTE
          : 0,
      })
      .eq("id", userId);
  }

  // 4. Expiración / reembolso / cancelación: revertir a gratuito si ya no es premium
  if (["EXPIRATION", "REFUND", "CANCELLATION"].includes(event.event?.type) && !isPremium) {
    await supabase
      .from("users")
      .update({ subscription_tier: "free", max_storage_bytes: 0 })
      .eq("id", userId);
  }

  return new Response("OK", { status: 200 });
});
