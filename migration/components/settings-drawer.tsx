"use client"

import { memo, useRef, useEffect } from "react"
import type { Language } from "@/lib/types"
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet"
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Separator } from "@/components/ui/separator"
import { Languages } from "lucide-react"

interface SettingsDrawerProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  primaryLanguage: Language
  secondaryLanguage: Language
  onPrimaryLanguageChange: (language: Language) => void
  onSecondaryLanguageChange: (language: Language) => void
}

const LANGUAGE_OPTIONS = [
  { value: "niv" as Language, label: "English (NIV)", description: "New International Version" },
  { value: "cuv" as Language, label: "中文和合本 (CUV)", description: "Chinese Union Version" },
  { value: "cu1" as Language, label: "新标点和合本", description: "Chinese Union Version with New Punctuation" },
]

const SECONDARY_LANGUAGE_OPTIONS = [
  { value: "none" as Language, label: "無", description: "僅顯示主要語言" },
  ...LANGUAGE_OPTIONS,
]

function arePropsEqual(prevProps: SettingsDrawerProps, nextProps: SettingsDrawerProps) {
  // If drawer is open and stays open, ignore language changes to prevent re-animation
  if (prevProps.open && nextProps.open) {
    return (
      prevProps.open === nextProps.open &&
      prevProps.onOpenChange === nextProps.onOpenChange &&
      prevProps.onPrimaryLanguageChange === nextProps.onPrimaryLanguageChange &&
      prevProps.onSecondaryLanguageChange === nextProps.onSecondaryLanguageChange
    )
  }
  // Otherwise, do normal comparison
  return (
    prevProps.open === nextProps.open &&
    prevProps.primaryLanguage === nextProps.primaryLanguage &&
    prevProps.secondaryLanguage === nextProps.secondaryLanguage &&
    prevProps.onOpenChange === nextProps.onOpenChange &&
    prevProps.onPrimaryLanguageChange === nextProps.onPrimaryLanguageChange &&
    prevProps.onSecondaryLanguageChange === nextProps.onSecondaryLanguageChange
  )
}

export const SettingsDrawer = memo(function SettingsDrawer({
  open,
  onOpenChange,
  primaryLanguage,
  secondaryLanguage,
  onPrimaryLanguageChange,
  onSecondaryLanguageChange,
}: SettingsDrawerProps) {
  // Use a stable key to prevent re-animation when language changes while open
  const sheetKeyRef = useRef(0)
  const wasOpenRef = useRef(open)
  
  useEffect(() => {
    // Only update the key when transitioning from closed to open
    if (open && !wasOpenRef.current) {
      sheetKeyRef.current += 1
    }
    wasOpenRef.current = open
  }, [open])

  return (
    <Sheet key={sheetKeyRef.current} open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-full sm:max-w-md px-4 sm:px-6">
        <SheetHeader>
          <SheetTitle className="flex items-center gap-2">
            <Languages className="h-5 w-5" />
            閱讀設定
          </SheetTitle>
        </SheetHeader>

        <div className="mt-6 space-y-6">
          {/* Primary Language */}
          <div className="space-y-4">
            <div>
              <Label className="text-base font-semibold">主要語言</Label>
              <p className="text-sm text-muted-foreground mt-1">以較大字體顯示</p>
            </div>

            <RadioGroup value={primaryLanguage} onValueChange={(value) => onPrimaryLanguageChange(value as Language)}>
              {LANGUAGE_OPTIONS.map((option) => (
                <div key={option.value} className="flex items-start space-x-3 space-y-0">
                  <RadioGroupItem value={option.value} id={`primary-${option.value}`} className="mt-1" />
                  <Label htmlFor={`primary-${option.value}`} className="flex-1 cursor-pointer">
                    <div className="font-medium">{option.label}</div>
                    <div className="text-sm text-muted-foreground">{option.description}</div>
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </div>

          <Separator />

          {/* Secondary Language */}
          <div className="space-y-4">
            <div>
              <Label className="text-base font-semibold">次要語言</Label>
              <p className="text-sm text-muted-foreground mt-1">以較小字體顯示於下方</p>
            </div>

            <RadioGroup
              value={secondaryLanguage}
              onValueChange={(value) => onSecondaryLanguageChange(value as Language)}
            >
              {SECONDARY_LANGUAGE_OPTIONS.map((option) => (
                <div key={option.value} className="flex items-start space-x-3 space-y-0">
                  <RadioGroupItem value={option.value} id={`secondary-${option.value}`} className="mt-1" />
                  <Label htmlFor={`secondary-${option.value}`} className="flex-1 cursor-pointer">
                    <div className="font-medium">{option.label}</div>
                    <div className="text-sm text-muted-foreground">{option.description}</div>
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  )
}, arePropsEqual)
