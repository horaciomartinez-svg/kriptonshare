import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _queueKey = 'funnel_event_queue';

const Set<String> kFunnelEventTypes = {
  'signup_completed',
  'first_link_created',
  'first_recipient_view',
  'paywall_shown',
  'paywall_cta_clicked',
  'paywall_dismissed',
  'checkout_started',
  'purchase_completed',
  'trial_started',
  'trial_expired',
};

class FunnelMetricsService {
  static final FunnelMetricsService _instance = FunnelMetricsService._internal();
  factory FunnelMetricsService() => _instance;
  FunnelMetricsService._internal();

  Future<void> logEvent(String eventType, {String? trigger, Map<String, dynamic>? metadata}) async {
    if (!kFunnelEventTypes.contains(eventType)) {
      debugPrint('[FunnelMetrics] Unknown event type: $eventType');
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final userId = user?.id;

      await supabase.from('funnel_events').insert({
        'user_id': userId,
        'event_type': eventType,
        'trigger': trigger,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
      });

      debugPrint('[FunnelMetrics] Logged: $eventType');
    } catch (e) {
      debugPrint('[FunnelMetrics] RPC failed, queuing locally: $eventType');
      await _queueEvent(eventType, trigger: trigger, metadata: metadata);
    }
  }

  Future<void> flushQueuedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null) return;

      final List<dynamic> queued = jsonDecode(raw);
      if (queued.isEmpty) return;

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final userId = user?.id;

      for (final entry in queued) {
        final Map<String, dynamic> event = Map<String, dynamic>.from(entry);

        try {
          await supabase.from('funnel_events').insert({
            'user_id': userId,
            'event_type': event['event_type'],
            'trigger': event['trigger'],
            'metadata': event['metadata'] != null ? jsonEncode(event['metadata']) : null,
          });
        } catch (e) {
          debugPrint('[FunnelMetrics] Flush failed for ${event['event_type']}, skipping');
        }
      }

      await prefs.remove(_queueKey);
      debugPrint('[FunnelMetrics] Flushed ${queued.length} queued event(s)');
    } catch (e) {
      debugPrint('[FunnelMetrics] flushQueuedEvents error: $e');
    }
  }

  Future<void> _queueEvent(String eventType, {String? trigger, Map<String, dynamic>? metadata}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      final List<dynamic> queue = raw != null ? jsonDecode(raw) : <dynamic>[];

      queue.add({
        'event_type': eventType,
        'trigger': trigger,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_queueKey, jsonEncode(queue));
    } catch (e) {
      debugPrint('[FunnelMetrics] Failed to queue event: $e');
    }
  }
}
