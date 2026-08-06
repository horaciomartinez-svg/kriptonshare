export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      access_logs: {
        Row: {
          id: string
          ip_address: string | null
          link_id: string
          user_agent: string | null
          viewed_at: string | null
        }
        Insert: {
          id?: string
          ip_address?: string | null
          link_id: string
          user_agent?: string | null
          viewed_at?: string | null
        }
        Update: {
          id?: string
          ip_address?: string | null
          link_id?: string
          user_agent?: string | null
          viewed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "access_logs_link_id_fkey"
            columns: ["link_id"]
            isOneToOne: false
            referencedRelation: "share_links"
            referencedColumns: ["id"]
          },
        ]
      }
      files: {
        Row: {
          aes_key_encrypted: string
          bucket_name: string | null
          conversion_status: string
          created_at: string | null
          downloads_count: number | null
          encryption_salt: string
          expires_at: string
          file_size_bytes: number
          folder_id: string | null
          id: string
          is_deleted: boolean | null
          mac_tag: string
          max_downloads: number | null
          mime_type: string
          nonce: string
          object_path: string
          original_filename: string
          owner_id: string
          salt: string
          status: string | null
          storage_object_key: string
          storage_provider: string
          updated_at: string | null
          viewer_file_size_bytes: number | null
          viewer_object_key: string | null
        }
        Insert: {
          aes_key_encrypted?: string
          bucket_name?: string | null
          conversion_status?: string
          created_at?: string | null
          downloads_count?: number | null
          encryption_salt: string
          expires_at?: string
          file_size_bytes: number
          folder_id?: string | null
          id?: string
          is_deleted?: boolean | null
          mac_tag?: string
          max_downloads?: number | null
          mime_type: string
          nonce?: string
          object_path: string
          original_filename: string
          owner_id: string
          salt?: string
          status?: string | null
          storage_object_key: string
          storage_provider?: string
          updated_at?: string | null
          viewer_file_size_bytes?: number | null
          viewer_object_key?: string | null
        }
        Update: {
          aes_key_encrypted?: string
          bucket_name?: string | null
          conversion_status?: string
          created_at?: string | null
          downloads_count?: number | null
          encryption_salt?: string
          expires_at?: string
          file_size_bytes?: number
          folder_id?: string | null
          id?: string
          is_deleted?: boolean | null
          mac_tag?: string
          max_downloads?: number | null
          mime_type?: string
          nonce?: string
          object_path?: string
          original_filename?: string
          owner_id?: string
          salt?: string
          status?: string | null
          storage_object_key?: string
          storage_provider?: string
          updated_at?: string | null
          viewer_file_size_bytes?: number | null
          viewer_object_key?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "files_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "files_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      folders: {
        Row: {
          created_at: string | null
          description: string | null
          id: string
          is_deleted: boolean | null
          name: string
          owner_id: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: string
          is_deleted?: boolean | null
          name: string
          owner_id: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: string
          is_deleted?: boolean | null
          name?: string
          owner_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "folders_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      journey_telemetry: {
        Row: {
          created_at: string | null
          duration_ms: number | null
          event_type: string
          file_id: string | null
          id: string
          page_number: number | null
          recipient_email: string | null
          recipient_ip: string | null
          share_link_id: string
        }
        Insert: {
          created_at?: string | null
          duration_ms?: number | null
          event_type: string
          file_id?: string | null
          id?: string
          page_number?: number | null
          recipient_email?: string | null
          recipient_ip?: string | null
          share_link_id: string
        }
        Update: {
          created_at?: string | null
          duration_ms?: number | null
          event_type?: string
          file_id?: string | null
          id?: string
          page_number?: number | null
          recipient_email?: string | null
          recipient_ip?: string | null
          share_link_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "journey_telemetry_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journey_telemetry_share_link_id_fkey"
            columns: ["share_link_id"]
            isOneToOne: false
            referencedRelation: "share_links"
            referencedColumns: ["id"]
          },
        ]
      }
      share_links: {
        Row: {
          access_count: number | null
          created_at: string | null
          created_by: string
          enable_watermark: boolean | null
          expires_at: string
          file_id: string | null
          folder_id: string | null
          id: string
          is_active: boolean | null
          last_accessed_at: string | null
          link_type: string
          pre_signed_url_hash: string | null
          recipient_email: string | null
          recipient_ip_cidr: unknown
          require_recipient_email: boolean | null
        }
        Insert: {
          access_count?: number | null
          created_at?: string | null
          created_by: string
          enable_watermark?: boolean | null
          expires_at: string
          file_id?: string | null
          folder_id?: string | null
          id?: string
          is_active?: boolean | null
          last_accessed_at?: string | null
          link_type?: string
          pre_signed_url_hash?: string | null
          recipient_email?: string | null
          recipient_ip_cidr?: unknown
          require_recipient_email?: boolean | null
        }
        Update: {
          access_count?: number | null
          created_at?: string | null
          created_by?: string
          enable_watermark?: boolean | null
          expires_at?: string
          file_id?: string | null
          folder_id?: string | null
          id?: string
          is_active?: boolean | null
          last_accessed_at?: string | null
          link_type?: string
          pre_signed_url_hash?: string | null
          recipient_email?: string | null
          recipient_ip_cidr?: unknown
          require_recipient_email?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "share_links_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "share_links_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "share_links_folder_id_fkey"
            columns: ["folder_id"]
            isOneToOne: false
            referencedRelation: "folders"
            referencedColumns: ["id"]
          },
        ]
      }
      telemetry_events: {
        Row: {
          created_at: string | null
          duration_ms: number
          event_type: string
          geolocation: Json | null
          id: number
          ip_address: unknown
          link_id: string
          page_number: number | null
          timestamp_ms: number
          user_agent: string | null
        }
        Insert: {
          created_at?: string | null
          duration_ms: number
          event_type: string
          geolocation?: Json | null
          id?: number
          ip_address?: unknown
          link_id: string
          page_number?: number | null
          timestamp_ms: number
          user_agent?: string | null
        }
        Update: {
          created_at?: string | null
          duration_ms?: number
          event_type?: string
          geolocation?: Json | null
          id?: number
          ip_address?: unknown
          link_id?: string
          page_number?: number | null
          timestamp_ms?: number
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "telemetry_events_link_id_fkey"
            columns: ["link_id"]
            isOneToOne: false
            referencedRelation: "share_links"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          created_at: string | null
          email: string
          id: string
          max_file_size_bytes: number | null
          max_links_monthly: number | null
          max_storage_bytes: number | null
          max_storage_premium_bytes: number | null
          monthly_links_generated: number | null
          monthly_links_reset_at: string | null
          preferred_language: string | null
          subscription_expires_at: string | null
          subscription_tier: string | null
          total_storage_used_bytes: number | null
          updated_at: string | null
          watermark_dynamic: boolean | null
        }
        Insert: {
          created_at?: string | null
          email: string
          id: string
          max_file_size_bytes?: number | null
          max_links_monthly?: number | null
          max_storage_bytes?: number | null
          max_storage_premium_bytes?: number | null
          monthly_links_generated?: number | null
          monthly_links_reset_at?: string | null
          preferred_language?: string | null
          subscription_expires_at?: string | null
          subscription_tier?: string | null
          total_storage_used_bytes?: number | null
          updated_at?: string | null
          watermark_dynamic?: boolean | null
        }
        Update: {
          created_at?: string | null
          email?: string
          id?: string
          max_file_size_bytes?: number | null
          max_links_monthly?: number | null
          max_storage_bytes?: number | null
          max_storage_premium_bytes?: number | null
          monthly_links_generated?: number | null
          monthly_links_reset_at?: string | null
          preferred_language?: string | null
          subscription_expires_at?: string | null
          subscription_tier?: string | null
          total_storage_used_bytes?: number | null
          updated_at?: string | null
          watermark_dynamic?: boolean | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      check_upload_limits: {
        Args: { p_file_size: number; p_user_id: string }
        Returns: {
          can_upload: boolean
          message: string
        }[]
      }
      get_received_files: {
        Args: never
        Returns: {
          bucket_name: string
          conversion_status: string
          created_at: string
          downloads_count: number
          expires_at: string
          file_size_bytes: number
          id: string
          is_active: boolean
          link_expires_at: string
          link_id: string
          max_downloads: number
          mime_type: string
          original_filename: string
          owner_id: string
          recipient_email: string
          status: string
          storage_object_key: string
          storage_provider: string
          viewer_file_size_bytes: number
          viewer_object_key: string
        }[]
      }
      get_shared_file_metadata: {
        Args: { p_link_id: string }
        Returns: {
          bucket_name: string
          conversion_status: string
          created_at: string
          downloads_count: number
          expires_at: string
          file_size_bytes: number
          id: string
          is_active: boolean
          link_expires_at: string
          link_id: string
          max_downloads: number
          mime_type: string
          original_filename: string
          owner_id: string
          recipient_email: string
          status: string
          storage_object_key: string
          storage_provider: string
          viewer_file_size_bytes: number
          viewer_object_key: string
        }[]
      }
      increment_file_download_count: {
        Args: { p_file_id: string }
        Returns: undefined
      }
      increment_link_access_count: {
        Args: { p_link_id: string }
        Returns: undefined
      }
      validate_share_link_expiration: {
        Args: { p_expires_at: string; p_user_id: string }
        Returns: {
          is_valid: boolean
          message: string
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const
