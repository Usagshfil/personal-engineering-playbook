/**
 * 06-technologies/web/examples/representative-feature.tsx
 * 
 * Reference Implementation: User Profile Editor
 * Demonstrating Tier 2 Web Frontend Engineering Standards in Practice.
 * 
 * Normative Standards Exercised:
 * - Strict TypeScript 5.5+ types & Discriminating Union state (MUST)
 * - Runtime boundary validation with Zod schema (MUST)
 * - WCAG 2.1 Level AA accessible form controls & live regions (MUST)
 * - Non-blocking UI transitions via useTransition for INP <= 200ms (SHOULD)
 * - Container-queried responsive styling with design tokens (SHOULD)
 * - Uncontrolled input performance via React Hook Form (SHOULD)
 */

'use client';

import React, { useState, useTransition } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// ============================================================================
// 1. RUNTIME VALIDATION CONTRACT (Zod) - MUST
// ============================================================================
export const profileSchema = z.object({
  fullName: z
    .string()
    .min(2, 'Full name must be at least 2 characters')
    .max(50, 'Full name cannot exceed 50 characters'),
  email: z
    .string()
    .email('Please enter a valid work email address'),
  role: z.enum(['engineer', 'designer', 'product', 'other'], {
    errorMap: () => ({ message: 'Please select a valid team role' }),
  }),
  bio: z
    .string()
    .max(200, 'Bio cannot exceed 200 characters')
    .optional(),
});

export type ProfileFormData = z.infer<typeof profileSchema>;

// ============================================================================
// 2. DISCRIMINATING UNION STATE MODELING - MUST
// ============================================================================
export type SubmissionState =
  | { readonly status: 'idle' }
  | { readonly status: 'submitting' }
  | { readonly status: 'success'; readonly timestamp: number; readonly profile: ProfileFormData }
  | { readonly status: 'error'; readonly message: string };

// ============================================================================
// 3. REPRESENTATIVE COMPONENT IMPLEMENTATION
// ============================================================================
interface UserProfileEditorProps {
  initialProfile?: Partial<ProfileFormData>;
  onSave?: (profile: ProfileFormData) => Promise<void>;
}

export function UserProfileEditor({
  initialProfile,
  onSave,
}: UserProfileEditorProps) {
  const [submissionState, setSubmissionState] = useState<SubmissionState>({
    status: 'idle',
  });
  
  // Non-blocking transition to keep main thread responsive (INP <= 200ms) - SHOULD
  const [isPending, startTransition] = useTransition();

  // Uncontrolled input performance via React Hook Form - SHOULD
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ProfileFormData>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      fullName: initialProfile?.fullName ?? '',
      email: initialProfile?.email ?? '',
      role: initialProfile?.role ?? 'engineer',
      bio: initialProfile?.bio ?? '',
    },
  });

  const onSubmit = (data: ProfileFormData) => {
    setSubmissionState({ status: 'submitting' });

    startTransition(async () => {
      try {
        if (onSave) {
          await onSave(data);
        } else {
          // Simulated asynchronous save with network delay
          await new Promise((resolve) => setTimeout(resolve, 600));
        }

        setSubmissionState({
          status: 'success',
          timestamp: Date.now(),
          profile: data,
        });
      } catch (err) {
        setSubmissionState({
          status: 'error',
          message: err instanceof Error ? err.message : 'Failed to update profile',
        });
      }
    });
  };

  return (
    // Container query root: adapts layout based on parent container width, not viewport - SHOULD
    <div className="@container w-full max-w-xl mx-auto p-4 sm:p-6 bg-card text-card-foreground rounded-xl border border-border shadow-sm">
      <header className="mb-6">
        <h2 className="text-xl font-bold tracking-tight text-foreground">
          Edit Team Profile
        </h2>
        <p className="text-sm text-muted-foreground mt-1">
          Update your public profile and workspace preferences.
        </p>
      </header>

      {/* Accessible Status Announcement Live Region - MUST */}
      {submissionState.status === 'success' && (
        <div
          role="status"
          aria-live="polite"
          className="mb-4 p-3 rounded-lg bg-green-500/10 text-green-600 dark:text-green-400 text-sm font-medium border border-green-500/20"
        >
          Profile successfully updated for {submissionState.profile.fullName}!
        </div>
      )}

      {submissionState.status === 'error' && (
        <div
          role="alert"
          aria-live="assertive"
          className="mb-4 p-3 rounded-lg bg-destructive/10 text-destructive text-sm font-medium border border-destructive/20"
        >
          {submissionState.message}
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4">
        {/* Full Name Field */}
        <div>
          <label
            htmlFor="profile-fullname"
            className="block text-sm font-medium text-foreground mb-1"
          >
            Full Name <span className="text-destructive" aria-hidden="true">*</span>
          </label>
          <input
            id="profile-fullname"
            type="text"
            autoComplete="name"
            aria-required="true"
            aria-invalid={errors.fullName ? 'true' : 'false'}
            aria-describedby={errors.fullName ? 'fullname-error' : undefined}
            {...register('fullName')}
            className="w-full px-3 py-2 rounded-md border border-input bg-background text-foreground text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          />
          {errors.fullName && (
            <p id="fullname-error" role="alert" className="mt-1 text-xs text-destructive">
              {errors.fullName.message}
            </p>
          )}
        </div>

        {/* Email Field */}
        <div>
          <label
            htmlFor="profile-email"
            className="block text-sm font-medium text-foreground mb-1"
          >
            Work Email Address <span className="text-destructive" aria-hidden="true">*</span>
          </label>
          <input
            id="profile-email"
            type="email"
            autoComplete="email"
            aria-required="true"
            aria-invalid={errors.email ? 'true' : 'false'}
            aria-describedby={errors.email ? 'email-error' : undefined}
            {...register('email')}
            className="w-full px-3 py-2 rounded-md border border-input bg-background text-foreground text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          />
          {errors.email && (
            <p id="email-error" role="alert" className="mt-1 text-xs text-destructive">
              {errors.email.message}
            </p>
          )}
        </div>

        {/* Role Selection Field */}
        <div>
          <label
            htmlFor="profile-role"
            className="block text-sm font-medium text-foreground mb-1"
          >
            Primary Role <span className="text-destructive" aria-hidden="true">*</span>
          </label>
          <select
            id="profile-role"
            aria-required="true"
            aria-invalid={errors.role ? 'true' : 'false'}
            aria-describedby={errors.role ? 'role-error' : undefined}
            {...register('role')}
            className="w-full px-3 py-2 rounded-md border border-input bg-background text-foreground text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          >
            <option value="engineer">Software Engineer</option>
            <option value="designer">Product Designer</option>
            <option value="product">Product Manager</option>
            <option value="other">Other Contributor</option>
          </select>
          {errors.role && (
            <p id="role-error" role="alert" className="mt-1 text-xs text-destructive">
              {errors.role.message}
            </p>
          )}
        </div>

        {/* Bio Field */}
        <div>
          <label
            htmlFor="profile-bio"
            className="block text-sm font-medium text-foreground mb-1"
          >
            Short Bio <span className="text-xs text-muted-foreground">(Optional)</span>
          </label>
          <textarea
            id="profile-bio"
            rows={3}
            aria-invalid={errors.bio ? 'true' : 'false'}
            aria-describedby={errors.bio ? 'bio-error' : undefined}
            {...register('bio')}
            className="w-full px-3 py-2 rounded-md border border-input bg-background text-foreground text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          />
          {errors.bio && (
            <p id="bio-error" role="alert" className="mt-1 text-xs text-destructive">
              {errors.bio.message}
            </p>
          )}
        </div>

        {/* Action Buttons: Responsive container layout - SHOULD */}
        <div className="pt-4 flex flex-col @sm:flex-row gap-3 justify-end">
          <button
            type="button"
            onClick={() => reset()}
            disabled={isPending}
            className="px-4 py-2 rounded-md border border-input bg-background text-foreground text-sm font-medium hover:bg-muted transition-colors disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          >
            Reset
          </button>
          <button
            type="submit"
            disabled={isPending}
            className="px-4 py-2 rounded-md bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            {isPending ? 'Saving Profile...' : 'Save Changes'}
          </button>
        </div>
      </form>
    </div>
  );
}
