@php
    $package = $package ?? null;
    $initialContexts = old('contexts', $package?->contexts?->map(function ($context) {
        return [
            'id' => $context->id,
            'context_type' => $context->context_type,
            'context_id' => $context->context_id,
            'sort_order' => $context->sort_order ?? 0,
        ];
    })->values()->all() ?? []);

    $initialGroups = old('groups', $package?->groups?->sortBy('sort_order')->values()->map(function ($group) {
        return [
            'id' => $group->id,
            'source_type' => $group->source_type ?? 'custom',
            'linked_type' => $group->linked_type,
            'linked_id' => $group->linked_id,
            'title' => $group->title,
            'subtitle' => $group->subtitle,
            'sort_order' => $group->sort_order ?? 0,
            'items' => $group->items->sortBy('sort_order')->values()->map(function ($item) {
                return [
                    'id' => $item->id,
                    'source_type' => $item->source_type ?? ($item->service_id ? 'linked' : 'custom'),
                    'service_id' => $item->service_id,
                    'name' => $item->name,
                    'subtitle' => $item->subtitle,
                    'custom_price' => $item->custom_price,
                    'custom_duration_minutes' => $item->custom_duration_minutes,
                    'is_required' => (bool) $item->is_required,
                    'is_default_selected' => (bool) $item->is_default_selected,
                    'sort_order' => $item->sort_order ?? 0,
                    'options' => $item->options->sortBy('sort_order')->values()->map(function ($option) {
                        return [
                            'id' => $option->id,
                            'name' => $option->name,
                            'subtitle' => $option->subtitle,
                            'price' => $option->price,
                            'duration_minutes' => $option->duration_minutes,
                            'is_default' => (bool) $option->is_default,
                            'sort_order' => $option->sort_order ?? 0,
                        ];
                    })->all(),
                ];
            })->all(),
        ];
    })->all() ?? []);

    $initialLinkedGroups = array_values(array_filter($initialGroups, fn ($group) => ($group['source_type'] ?? 'custom') === 'linked'));
    $initialCustomGroups = array_values(array_filter($initialGroups, fn ($group) => ($group['source_type'] ?? 'custom') !== 'linked'));
    $primaryContext = $initialContexts[0] ?? ['id' => null, 'context_type' => 'service_group', 'context_id' => null, 'sort_order' => 0];
    $pageActionLabel = $mode === 'edit' ? 'Update Package' : 'Create Package';
@endphp

<style>
  #package-form,
  #package-form * { box-sizing: border-box; }
  #package-form .row { display: grid; grid-template-columns: repeat(12, minmax(0, 1fr)); gap: 16px; margin: 0; }
  #package-form .col-md-1 { grid-column: span 1; }
  #package-form .col-md-2 { grid-column: span 2; }
  #package-form .col-md-3 { grid-column: span 3; }
  #package-form .col-md-4 { grid-column: span 4; }
  #package-form .col-md-5 { grid-column: span 5; }
  #package-form .col-md-6 { grid-column: span 6; }
  #package-form .col-md-7 { grid-column: span 7; }
  #package-form .col-md-8 { grid-column: span 8; }
  #package-form .col-md-12 { grid-column: span 12; }
  #package-form .mb-0 { margin-bottom: 0 !important; }
  #package-form .mb-1 { margin-bottom: .25rem !important; }
  #package-form .mb-2 { margin-bottom: .5rem !important; }
  #package-form .mb-3 { margin-bottom: 0 !important; }
  #package-form .mt-0 { margin-top: 0 !important; }
  #package-form .mt-1 { margin-top: .25rem !important; }
  #package-form .mt-2 { margin-top: .5rem !important; }
  #package-form .mt-3 { margin-top: 1rem !important; }
  #package-form .mt-4 { margin-top: 1.25rem !important; }
  #package-form .ml-auto { margin-left: auto !important; }
  #package-form .d-flex { display: flex !important; }
  #package-form .flex-wrap { flex-wrap: wrap !important; }
  #package-form .flex-column { flex-direction: column !important; }
  #package-form .flex-grow-1 { flex: 1 1 auto !important; }
  #package-form .align-items-center { align-items: center !important; }
  #package-form .align-items-start { align-items: flex-start !important; }
  #package-form .align-items-end { align-items: flex-end !important; }
  #package-form .justify-content-between { justify-content: space-between !important; }
  #package-form .justify-content-end { justify-content: flex-end !important; }
  #package-form .gap-2 { gap: .5rem !important; }
  #package-form .gap-3 { gap: .75rem !important; }
  #package-form .text-right { text-align: right !important; }
  #package-form .font-weight-bold { font-weight: 700 !important; }
  #package-form .form-control,
  #package-form input[type="text"],
  #package-form input[type="number"],
  #package-form input[type="file"],
  #package-form select,
  #package-form textarea {
    width: 100%;
    min-height: 48px;
    border: 1px solid #d7dfeb;
    border-radius: 14px;
    background: #fff;
    color: #0f172a;
    font-size: .96rem;
    line-height: 1.35;
    padding: 12px 14px;
    outline: none;
    transition: border-color .18s ease, box-shadow .18s ease, background-color .18s ease;
  }
  #package-form textarea { min-height: 112px; resize: vertical; }
  #package-form input[type="file"] { padding: 10px 12px; }
  #package-form .form-control:focus,
  #package-form input:focus,
  #package-form select:focus,
  #package-form textarea:focus {
    border-color: #2563eb;
    box-shadow: 0 0 0 4px rgba(37, 99, 235, .10);
  }
  #package-form .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: .45rem;
    min-height: 44px;
    padding: 0 16px;
    border-radius: 12px;
    border: 1px solid transparent;
    font-size: .92rem;
    font-weight: 600;
    text-decoration: none;
    cursor: pointer;
    transition: all .18s ease;
  }
  #package-form .btn-primary { background: #2563eb; color: #fff; border-color: #2563eb; }
  #package-form .btn-primary:hover { background: #1d4ed8; border-color: #1d4ed8; }
  #package-form .btn-outline-primary { background: #fff; color: #2563eb; border-color: #bfd3ff; }
  #package-form .btn-outline-secondary { background: #fff; color: #334155; border-color: #cbd5e1; }
  #package-form .btn-outline-danger { background: #fff; color: #dc2626; border-color: #fecaca; }
  #package-form .btn-outline-primary:hover,
  #package-form .btn-outline-secondary:hover,
  #package-form .btn-outline-danger:hover { background: #f8fafc; }
  #package-form .btn-sm { min-height: 38px; padding: 0 12px; font-size: .84rem; }
  .package-form-card { border: 1px solid #e5e7eb; border-radius: 24px; background: #fff; box-shadow: 0 18px 40px rgba(15, 23, 42, 0.06); }
  .package-form-card .card-header { background: linear-gradient(180deg, #ffffff 0%, #fbfdff 100%); border-bottom: 1px solid #eef2f7; border-radius: 24px 24px 0 0; padding: 1.4rem 1.6rem; }
  .package-form-card .card-body { padding: 1.75rem; background: #fcfcfd; }
  .flow-step { border: 1px solid #e6ebf2; border-radius: 20px; background: #fff; padding: 1.25rem; margin-bottom: 24px; box-shadow: 0 10px 24px rgba(15, 23, 42, 0.035); }
  .flow-step-header { display: flex; align-items: flex-start; gap: 14px; margin-bottom: 18px; }
  .flow-step-badge { width: 34px; height: 34px; border-radius: 999px; background: #eff6ff; color: #1d4ed8; display: inline-flex; align-items: center; justify-content: center; font-size: .9rem; font-weight: 700; flex-shrink: 0; }
  .flow-step-title { font-size: 1.1rem; font-weight: 700; color: #0f172a; margin: 0 0 2px; }
  .flow-step-copy { color: #64748b; font-size: .92rem; margin: 0; }
  .package-section-title { font-size: .78rem; font-weight: 700; letter-spacing: .14em; text-transform: uppercase; color: #64748b; margin-bottom: .65rem; }
  .package-helper { color: #64748b; font-size: .92rem; }
  .builder-panel { border: 1px solid #e9eef5; border-radius: 18px; padding: 14px 16px; background: #f8fafc; }
  .builder-panel + .builder-panel { margin-top: 16px; }
  .builder-chip { display: inline-flex; align-items: center; gap: .4rem; border: 1px solid #dbeafe; background: #eff6ff; color: #1d4ed8; border-radius: 999px; padding: .25rem .72rem; font-size: .83rem; font-weight: 600; }
  .selected-summary { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
  .selected-summary-pill { display: inline-flex; align-items: center; gap: 6px; padding: .42rem .7rem; border-radius: 999px; background: #f1f5f9; color: #0f172a; font-size: .84rem; }
  #linked-groups-list { display: grid !important; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)) !important; gap: 16px !important; align-items: stretch; caret-color: transparent; }
  #linked-groups-list * { caret-color: transparent; }
  .linked-group-cell { min-width: 0; width: 100%; }
  .linked-group-card { display: flex; flex-direction: column; width: 100%; min-height: 96px; border: 1px solid #dbe3ef; border-radius: 16px; padding: 0; background: #fff; overflow: hidden; cursor: pointer; transition: border-color .18s ease, box-shadow .18s ease, transform .18s ease, background-color .18s ease; position: relative; user-select: none; }
  .linked-group-card:hover { border-color: #94a3b8; transform: translateY(-1px); }
  .linked-group-card.active { border-color: #2563eb; background: #f8fbff; box-shadow: 0 0 0 3px rgba(37,99,235,.08); }
  .linked-group-card:focus,
  .linked-group-card:focus-visible,
  .linked-group-head:focus,
  .linked-group-head:focus-visible { outline: none; }
  .linked-group-card::before,
  .linked-group-card::after,
  .linked-group-head::before,
  .linked-group-head::after { content: none !important; display: none !important; }
  .linked-group-head { display: flex; align-items: flex-start; gap: 12px; padding: 16px; border-bottom: 0; min-height: 0; width: 100%; }
  .linked-group-check { width: 18px; height: 18px; }
  .linked-group-title { font-size: 1rem; font-weight: 700; color: #0f172a; margin: 0; line-height: 1.25; }
  .linked-group-subtitle { color: #64748b; font-size: .86rem; margin: 4px 0 0; }
  .linked-group-count { font-size: .82rem; color: #2563eb; font-weight: 600; margin-top: 6px; }
  .linked-item-row { border: 1px solid #edf2f7; border-radius: 14px; padding: 14px 16px; background: #fff; }
  .linked-item-row + .linked-item-row { margin-top: 12px; }
  #linked-items-wrapper .builder-panel { margin-bottom: 16px; }
  #linked-items-wrapper .linked-items-list { display: grid; grid-template-columns: 1fr; gap: 12px; }
  #linked-items-wrapper .linked-item-row + .linked-item-row { margin-top: 0; }
  .linked-item-label { display: flex; align-items: flex-start; gap: 12px; margin: 0; width: 100%; }
  .linked-item-check { margin-top: 3px; width: 18px; height: 18px; flex-shrink: 0; }
  .linked-item-meta { color: #64748b; font-size: .85rem; }
  .linked-item-title { font-weight: 600; color: #0f172a; margin-bottom: 4px; }
  .linked-item-controls { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 10px; padding-left: 30px; }
  .toggle-chip { display: inline-flex; align-items: center; gap: 8px; padding: .4rem .65rem; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 999px; color: #334155; font-size: .83rem; }
  .empty-state { border: 1px dashed #cbd5e1; border-radius: 14px; padding: 1rem; color: #64748b; background: #fff; }
  .custom-option { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: .75rem; }
  .custom-item { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: .9rem; }
  .custom-group { background: #fafafa; border: 1px solid #dbe3ef; border-radius: 18px; padding: 1rem; }
  .section-hidden { display: none !important; }
  .sticky-actions { position: sticky; bottom: 0; background: rgba(255,255,255,.96); border-top: 1px solid #e5e7eb; padding-top: 1rem; margin-top: 1.5rem; backdrop-filter: blur(10px); }
  @media (max-width: 767px) {
    #linked-groups-list { grid-template-columns: 1fr !important; }
    #package-form .row { grid-template-columns: 1fr; }
    #package-form [class*="col-md-"] { grid-column: span 1; }
    .package-form-card .card-body { padding: 1rem; }
    .flow-step { padding: 1rem; }
    .flow-step-header { gap: 10px; }
    .linked-item-controls { padding-left: 0; }
  }
  @media (min-width: 1200px) {
    #linked-items-wrapper .linked-items-list { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  }
</style>

<form method="POST" action="{{ $submitRoute }}" enctype="multipart/form-data" id="package-form">
  @csrf
  @if ($submitMethod !== 'POST')
    @method($submitMethod)
  @endif

  @if ($errors->any())
    <div class="alert alert-danger">
      <strong>Package could not be saved.</strong>
      <ul class="mb-0 mt-2 pl-3">
        @foreach ($errors->all() as $error)
          <li>{{ $error }}</li>
        @endforeach
      </ul>
    </div>
  @endif

  <div class="package-form-card">
    <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
      <div>
        <h3 class="mb-1">{{ $pageActionLabel }}</h3>
        <p class="package-helper mb-0">One engine for hierarchy, hybrid, and manual packages. Linked packages stay tied to the live service catalog.</p>
      </div>
      @if ($package)
        <span class="builder-chip">Package #{{ $package->id }}</span>
      @endif
    </div>

    <div class="card-body">
      <section class="flow-step">
        <div class="flow-step-header">
          <div class="flow-step-badge">1</div>
          <div>
            <h4 class="flow-step-title">Package Info</h4>
            <p class="flow-step-copy">Start with the core identity of the package. This should read like the final package card the customer sees.</p>
          </div>
        </div>
        <div class="row">
          <div class="col-md-6 mb-3">
            <div class="package-section-title">Package Title</div>
            <input type="text" name="name" class="form-control" value="{{ old('name', $package?->name) }}" required>
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Package Mode</div>
            <select name="package_mode" id="package_mode" class="form-control">
              @php $currentMode = old('package_mode', $package?->package_mode ?? 'hierarchy'); @endphp
              <option value="hierarchy" @selected($currentMode === 'hierarchy')>Hierarchy</option>
              <option value="hybrid" @selected($currentMode === 'hybrid')>Hybrid</option>
              <option value="manual" @selected($currentMode === 'manual')>Manual</option>
            </select>
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Package Image</div>
            <input type="file" name="package_image" class="form-control">
            @if ($package?->image)
              <small class="d-block mt-2"><a href="{{ $package->image }}" target="_blank" rel="noopener">Current image</a></small>
            @endif
          </div>
          <div class="col-md-7 mb-3">
            <div class="package-section-title">Short Description</div>
            <textarea name="short_description" class="form-control" rows="3">{{ old('short_description', $package?->short_description) }}</textarea>
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Tag Label</div>
            <input type="text" name="tag_label" class="form-control" value="{{ old('tag_label', $package?->tag_label) }}" placeholder="PACKAGE / SUPER SAVER">
          </div>
          <div class="col-md-2 mb-3">
            <div class="package-section-title">Sort Order</div>
            <input type="number" min="0" name="sort_order" class="form-control" value="{{ old('sort_order', $package?->sort_order ?? 0) }}">
          </div>
        </div>
      </section>

      <section class="flow-step" id="context-section">
        <div class="flow-step-header">
          <div class="flow-step-badge">2</div>
          <div>
            <h4 class="flow-step-title">Context Selection</h4>
            <p class="flow-step-copy">Pick the Level 2 page where this package should appear. Bridal uses Category, Luxe/Prime/Ayurveda use Service Group.</p>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 mb-3">
            <div class="package-section-title">Context Type</div>
            <select id="context_type" class="form-control">
              <option value="">Select context type</option>
              <option value="category" @selected(($primaryContext['context_type'] ?? null) === 'category')>Category</option>
              <option value="service_group" @selected(($primaryContext['context_type'] ?? null) === 'service_group')>Service Group</option>
            </select>
          </div>
          <div class="col-md-8 mb-3">
            <div class="package-section-title">Context Record</div>
            <select id="context_id" class="form-control">
              <option value="">Select a context first</option>
            </select>
          </div>
        </div>
      </section>

      <section class="flow-step" id="linked-builder-section">
        <div class="flow-step-header">
          <div class="flow-step-badge">3</div>
          <div>
            <h4 class="flow-step-title">Choose Groups And Services</h4>
            <p class="flow-step-copy">Step 1: Select groups. Step 2: Choose services inside selected groups.</p>
          </div>
        </div>
        <div class="builder-panel">
          <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
            <span class="builder-chip" id="linked-summary-chip">0 linked groups selected</span>
          </div>
          <div id="linked-groups-loading" class="empty-state section-hidden">Loading available groups...</div>
          <div id="linked-groups-empty" class="empty-state">Choose a context to load linked groups.</div>
          <div id="linked-groups-list" class="row g-3"></div>
        </div>
        <div class="builder-panel mt-3">
          <div class="package-section-title">Selected Services</div>
          <div id="linked-selected-summary" class="selected-summary">
            <span class="package-helper">No services selected yet.</span>
          </div>
        </div>
        <div class="mt-3" id="linked-items-wrapper"></div>
      </section>

      <section class="flow-step" id="custom-builder-section">
        <div class="flow-step-header">
          <div class="flow-step-badge">4</div>
          <div>
            <h4 class="flow-step-title">Custom Inclusions</h4>
            <p class="flow-step-copy">Use this for hybrid/manual rows that are not part of the linked service hierarchy, such as bridal-only inclusions or consultation notes.</p>
          </div>
        </div>
        <div class="builder-panel">
          <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
            <span class="package-helper">Linked rows and custom rows can coexist in hybrid mode.</span>
            <button type="button" class="btn btn-outline-primary btn-sm" id="add-custom-group">Add Custom Group</button>
          </div>
          <div id="custom-groups-empty" class="empty-state">No custom groups yet.</div>
          <div id="custom-groups-list"></div>
        </div>
      </section>

      <section class="flow-step">
        <div class="flow-step-header">
          <div class="flow-step-badge">5</div>
          <div>
            <h4 class="flow-step-title">Pricing And Controls</h4>
            <p class="flow-step-copy">Set the threshold and discount rule. Discount is applied only when the selected total meets the threshold.</p>
          </div>
        </div>
        <div class="row">
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Display / Fallback Price</div>
            <input type="number" step="0.01" min="0" name="package_price" class="form-control" value="{{ old('package_price', $package?->price ?? 0) }}" required>
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Base Price Threshold</div>
            <input type="number" step="0.01" min="0" name="base_price_threshold" class="form-control" value="{{ old('base_price_threshold', $package?->base_price_threshold ?? $package?->price ?? 0) }}">
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Discount Type</div>
            <select name="discount_type" class="form-control">
              @php $discountType = old('discount_type', $package?->discount_type); @endphp
              <option value="">None</option>
              <option value="percentage" @selected($discountType === 'percentage')>Percentage</option>
              <option value="fixed" @selected($discountType === 'fixed')>Fixed</option>
            </select>
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Discount Value</div>
            <input type="number" step="0.01" min="0" name="discount_value" class="form-control" value="{{ old('discount_value', $package?->discount_value) }}">
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Legacy Discount %</div>
            <input type="number" step="0.01" min="0" max="100" name="discount" class="form-control" value="{{ old('discount', $package?->discount ?? 0) }}">
          </div>
          <div class="col-md-3 mb-3">
            <div class="package-section-title">Display Duration (minutes)</div>
            <input type="number" min="0" name="duration" class="form-control" value="{{ old('duration', $package?->duration ?? 0) }}">
          </div>
          <div class="col-md-6 mb-3">
            <div class="package-section-title">Package Controls</div>
            <div class="d-flex flex-wrap gap-3">
              <label class="toggle-chip mb-0">
                <input class="form-check-input mt-0" type="checkbox" name="featured" value="1" @checked(old('featured', $package?->featured))>
                <span>Featured</span>
              </label>
              <label class="toggle-chip mb-0">
                <input class="form-check-input mt-0" type="checkbox" name="quantity_allowed" value="1" @checked(old('quantity_allowed', $package?->quantity_allowed))>
                <span>Allow quantity &gt; 1</span>
              </label>
              <label class="toggle-chip mb-0">
                <input class="form-check-input mt-0" type="checkbox" name="is_configurable" value="1" @checked(old('is_configurable', $package?->is_configurable ?? true))>
                <span>Configurable package</span>
              </label>
            </div>
          </div>
        </div>
      </section>

      <section class="flow-step">
        <div class="flow-step-header">
          <div class="flow-step-badge">6</div>
          <div>
            <h4 class="flow-step-title">Descriptions And Aftercare</h4>
            <p class="flow-step-copy">Optional content blocks for the customer-facing package detail and aftercare guidance.</p>
          </div>
        </div>
        <div class="row">
          <div class="col-md-6 mb-3">
            <div class="package-section-title">Description Title</div>
            <input type="text" name="desc_title" class="form-control" value="{{ old('desc_title', $package?->desc_title) }}">
          </div>
          <div class="col-md-6 mb-3">
            <div class="package-section-title">Description Image</div>
            <input type="file" name="desc_image" class="form-control">
            @if ($package?->desc_image)
              <small class="d-block mt-2"><a href="{{ $package->desc_image }}" target="_blank" rel="noopener">Current description image</a></small>
            @endif
          </div>
          <div class="col-md-6 mb-3">
            <div class="package-section-title">Description Content</div>
            <textarea name="desc_content" class="form-control" rows="5">{{ old('desc_content', $package?->description) }}</textarea>
          </div>
          <div class="col-md-6 mb-3">
            <div class="package-section-title">Aftercare Content</div>
            <textarea name="aftercare_content" class="form-control" rows="5">{{ old('aftercare_content', $package?->aftercare_content) }}</textarea>
          </div>
          <div class="col-md-6 mb-3">
            <div class="package-section-title">Aftercare Image</div>
            <input type="file" name="aftercare_image" class="form-control">
            @if ($package?->aftercare_image)
              <small class="d-block mt-2"><a href="{{ $package->aftercare_image }}" target="_blank" rel="noopener">Current aftercare image</a></small>
            @endif
          </div>
        </div>
      </section>

      <div id="hidden-payload"></div>

      <div class="sticky-actions d-flex justify-content-between align-items-center flex-wrap gap-2">
        <span class="package-helper">Create/edit supports hierarchy, hybrid, and manual packages. Linked rows are saved as references, not duplicated text catalog rows.</span>
        <div class="d-flex gap-2">
          <button type="submit" class="btn btn-outline-secondary" name="form_action" value="draft">Save Draft</button>
          <button type="submit" class="btn btn-primary" name="form_action" value="publish">Save & Publish</button>
        </div>
      </div>
    </div>
  </div>
</form>

<script>
  window.packageFormBoot = {
    initialContext: @json($primaryContext),
    initialLinkedGroups: @json($initialLinkedGroups),
    initialCustomGroups: @json($initialCustomGroups),
    categories: @json($categories->map(fn ($item) => ['id' => $item->id, 'name' => $item->name, 'slug' => $item->slug])->values()->all()),
    serviceGroups: @json($serviceGroups->map(fn ($item) => ['id' => $item->id, 'name' => $item->name, 'slug' => $item->slug])->values()->all()),
    linkedGroupsUrl: @json(route('packages.linked-groups')),
    linkedItemsUrl: @json(route('packages.linked-group-items')),
  };
</script>

<script>
  (function () {
    const boot = window.packageFormBoot || {};
    const form = document.getElementById('package-form');
    if (!form) return;

    const modeSelect = document.getElementById('package_mode');
    const contextSection = document.getElementById('context-section');
    const linkedSection = document.getElementById('linked-builder-section');
    const customSection = document.getElementById('custom-builder-section');
    const contextTypeSelect = document.getElementById('context_type');
    const contextIdSelect = document.getElementById('context_id');
    const linkedGroupsList = document.getElementById('linked-groups-list');
    const linkedGroupsEmpty = document.getElementById('linked-groups-empty');
    const linkedGroupsLoading = document.getElementById('linked-groups-loading');
    const linkedItemsWrapper = document.getElementById('linked-items-wrapper');
    const linkedSummaryChip = document.getElementById('linked-summary-chip');
    const linkedSelectedSummary = document.getElementById('linked-selected-summary');
    const customGroupsList = document.getElementById('custom-groups-list');
    const customGroupsEmpty = document.getElementById('custom-groups-empty');
    const hiddenPayload = document.getElementById('hidden-payload');

    const state = {
      context: {
        id: boot.initialContext?.id ?? null,
        context_type: boot.initialContext?.context_type ?? '',
        context_id: boot.initialContext?.context_id ?? '',
        sort_order: boot.initialContext?.sort_order ?? 0,
      },
      availableGroups: [],
      linkedGroups: (boot.initialLinkedGroups || []).map(normalizeLinkedGroup),
      customGroups: (boot.initialCustomGroups || []).map(normalizeCustomGroup),
      itemCandidates: {},
    };

    function normalizeLinkedGroup(group) {
      return {
        id: group.id ?? null,
        source_type: 'linked',
        linked_type: group.linked_type,
        linked_id: Number(group.linked_id),
        title: group.title ?? '',
        subtitle: group.subtitle ?? '',
        sort_order: Number(group.sort_order ?? 0),
        items: (group.items || []).map(item => ({
          id: item.id ?? null,
          source_type: 'linked',
          service_id: Number(item.service_id),
          title: item.name ?? '',
          subtitle: item.subtitle ?? '',
          is_required: Boolean(item.is_required),
          is_default_selected: item.is_default_selected === false ? false : Boolean(item.is_default_selected ?? true),
          sort_order: Number(item.sort_order ?? 0),
        })),
      };
    }

    function normalizeCustomGroup(group) {
      return {
        id: group.id ?? null,
        source_type: 'custom',
        title: group.title ?? '',
        subtitle: group.subtitle ?? '',
        sort_order: Number(group.sort_order ?? 0),
        items: (group.items || []).map(item => ({
          id: item.id ?? null,
          source_type: 'custom',
          name: item.name ?? '',
          subtitle: item.subtitle ?? '',
          custom_price: item.custom_price ?? '',
          custom_duration_minutes: item.custom_duration_minutes ?? '',
          is_required: Boolean(item.is_required),
          is_default_selected: item.is_default_selected === false ? false : Boolean(item.is_default_selected ?? true),
          sort_order: Number(item.sort_order ?? 0),
          options: (item.options || []).map(option => ({
            id: option.id ?? null,
            name: option.name ?? '',
            subtitle: option.subtitle ?? '',
            price: option.price ?? '',
            duration_minutes: option.duration_minutes ?? '',
            is_default: Boolean(option.is_default),
            sort_order: Number(option.sort_order ?? 0),
          })),
        })),
      };
    }

    function getCurrentMode() {
      return modeSelect.value || 'hierarchy';
    }

    function setSectionVisibility() {
      const mode = getCurrentMode();
      const showLinked = mode === 'hierarchy' || mode === 'hybrid';
      const showCustom = mode === 'hybrid' || mode === 'manual';
      contextSection.classList.toggle('section-hidden', !showLinked);
      linkedSection.classList.toggle('section-hidden', !showLinked);
      customSection.classList.toggle('section-hidden', !showCustom);
    }

    function populateContextOptions() {
      const type = contextTypeSelect.value;
      const options = type === 'category' ? (boot.categories || []) : type === 'service_group' ? (boot.serviceGroups || []) : [];
      contextIdSelect.innerHTML = '<option value="">Select record</option>';
      options.forEach(option => {
        const el = document.createElement('option');
        el.value = option.id;
        el.textContent = `${option.name} (#${option.id})`;
        if (String(option.id) === String(state.context.context_id)) el.selected = true;
        contextIdSelect.appendChild(el);
      });
    }

    async function fetchLinkedGroups() {
      if (!contextTypeSelect.value || !contextIdSelect.value) {
        state.availableGroups = [];
        renderLinkedGroups();
        renderLinkedItems();
        syncHiddenPayload();
        return;
      }

      linkedGroupsLoading.classList.remove('section-hidden');
      linkedGroupsEmpty.classList.add('section-hidden');
      linkedGroupsList.innerHTML = '';

      try {
        const params = new URLSearchParams({
          context_type: contextTypeSelect.value,
          context_id: contextIdSelect.value,
        });
        const response = await fetch(`${boot.linkedGroupsUrl}?${params.toString()}`, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
        const payload = await response.json();
        state.availableGroups = Array.isArray(payload.data) ? payload.data : [];
      } catch (error) {
        console.error(error);
        state.availableGroups = [];
      } finally {
        linkedGroupsLoading.classList.add('section-hidden');
        renderLinkedGroups();
        await preloadLinkedItems();
      }
    }

    function renderLinkedGroups() {
      linkedGroupsList.innerHTML = '';
      const available = state.availableGroups || [];
      linkedSummaryChip.textContent = `${state.linkedGroups.length} linked group${state.linkedGroups.length === 1 ? '' : 's'} selected`;

      if (!available.length) {
        linkedGroupsEmpty.textContent = contextIdSelect.value ? 'No linked groups found for this context.' : 'Choose a context to load linked groups.';
        linkedGroupsEmpty.classList.remove('section-hidden');
        return;
      }

      linkedGroupsEmpty.classList.add('section-hidden');

      available.forEach((group, index) => {
        const selected = state.linkedGroups.find(item => item.linked_type === group.type && Number(item.linked_id) === Number(group.id));
        const col = document.createElement('div');
        col.className = 'linked-group-cell';
        col.innerHTML = `
          <div class="linked-group-card ${selected ? 'active' : ''}" data-group-type="${group.type}" data-group-id="${group.id}">
            <div class="linked-group-head">
              <input type="checkbox" class="linked-group-toggle linked-group-check" ${selected ? 'checked' : ''} data-group-type="${group.type}" data-group-id="${group.id}" data-title="${escapeAttr(group.title)}" data-subtitle="${escapeAttr(group.subtitle || '')}">
              <div class="flex-grow-1">
                <p class="linked-group-title">${escapeHtml(group.title)}</p>
                <p class="linked-group-subtitle">${escapeHtml(group.subtitle || '')}</p>
                ${selected ? `<div class="linked-group-count">${selected.items.length} services selected</div>` : ''}
              </div>
            </div>
          </div>
        `;
        linkedGroupsList.appendChild(col);
      });

      linkedGroupsList.querySelectorAll('.linked-group-card').forEach(card => {
        card.addEventListener('click', (event) => {
          if (event.target.closest('.linked-group-toggle')) {
            return;
          }

          const checkbox = card.querySelector('.linked-group-toggle');
          if (!checkbox) return;
          checkbox.checked = !checkbox.checked;
          checkbox.dispatchEvent(new Event('change', { bubbles: true }));
        });
      });

      linkedGroupsList.querySelectorAll('.linked-group-toggle').forEach(toggle => {
        toggle.addEventListener('change', async (event) => {
          const target = event.currentTarget;
          const keyType = target.dataset.groupType;
          const keyId = Number(target.dataset.groupId);
          const existingIndex = state.linkedGroups.findIndex(group => group.linked_type === keyType && Number(group.linked_id) === keyId);

          if (target.checked && existingIndex === -1) {
            state.linkedGroups.push({
              id: null,
              source_type: 'linked',
              linked_type: keyType,
              linked_id: keyId,
              title: target.dataset.title || '',
              subtitle: target.dataset.subtitle || '',
              sort_order: state.linkedGroups.length,
              items: [],
            });
          }

          if (!target.checked && existingIndex !== -1) {
            state.linkedGroups.splice(existingIndex, 1);
            delete state.itemCandidates[`${keyType}:${keyId}`];
          }

          renderLinkedGroups();
          await preloadLinkedItems();
          syncHiddenPayload();
        });
      });
    }

    async function preloadLinkedItems() {
      const selectedGroups = [...state.linkedGroups];
      for (const group of selectedGroups) {
        const key = `${group.linked_type}:${group.linked_id}`;
        if (!state.itemCandidates[key]) {
          const params = new URLSearchParams({ group_type: group.linked_type, group_id: group.linked_id });
          const response = await fetch(`${boot.linkedItemsUrl}?${params.toString()}`, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
          const payload = await response.json();
          state.itemCandidates[key] = Array.isArray(payload.data) ? payload.data : [];
        }
      }
      renderLinkedItems();
      syncHiddenPayload();
    }

    function renderLinkedItems() {
      linkedItemsWrapper.innerHTML = '';
      renderSelectedSummary();

      if (!state.linkedGroups.length) {
        linkedItemsWrapper.innerHTML = '<div class="empty-state">Select one or more linked groups to choose Level 4 services.</div>';
        return;
      }

      state.linkedGroups
        .sort((a, b) => a.sort_order - b.sort_order)
        .forEach((group) => {
          const key = `${group.linked_type}:${group.linked_id}`;
          const candidates = state.itemCandidates[key] || [];
          const section = document.createElement('div');
          section.className = 'builder-panel';
          section.innerHTML = `
            <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
              <div>
                <h5 class="mb-1">${escapeHtml(group.title || resolveGroupTitle(group))}</h5>
                <div class="linked-item-meta">${escapeHtml(group.subtitle || '')}</div>
              </div>
              <span class="builder-chip">${group.items.length} linked service${group.items.length === 1 ? '' : 's'}</span>
            </div>
            <div class="linked-items-list"></div>
          `;

          const list = section.querySelector('.linked-items-list');
          if (!candidates.length) {
            list.innerHTML = '<div class="empty-state">No services found under this linked group.</div>';
          } else {
            candidates.forEach((candidate, index) => {
              const selectedItem = group.items.find(item => Number(item.service_id) === Number(candidate.id));
              const row = document.createElement('div');
              row.className = 'linked-item-row';
              row.innerHTML = `
                <div>
                  <label class="linked-item-label">
                    <input type="checkbox" class="linked-item-toggle linked-item-check" ${selectedItem ? 'checked' : ''} data-group-key="${key}" data-service-id="${candidate.id}" data-title="${escapeAttr(candidate.title || '')}" data-subtitle="${escapeAttr(candidate.subtitle || '')}">
                    <div>
                      <div class="linked-item-title">${escapeHtml(candidate.title)}</div>
                      <div class="linked-item-meta">${escapeHtml(candidate.subtitle || '')}</div>
                      <div class="linked-item-meta mt-1">Default price Rs ${formatNumber(candidate.price)} · ${candidate.duration_minutes || 0} min${candidate.has_variants ? ` · ${candidate.variant_count} variants` : ''}</div>
                    </div>
                  </label>
                  <div class="linked-item-controls">
                    <label class="toggle-chip mb-0">
                      <input type="checkbox" class="linked-item-default" data-group-key="${key}" data-service-id="${candidate.id}" ${selectedItem ? (selectedItem.is_default_selected ? 'checked' : '') : 'checked'}>
                      <span>Default selected</span>
                    </label>
                    <label class="toggle-chip mb-0">
                      <input type="checkbox" class="linked-item-required" data-group-key="${key}" data-service-id="${candidate.id}" ${selectedItem?.is_required ? 'checked' : ''}>
                      <span>Required</span>
                    </label>
                  </div>
                </div>
              `;
              list.appendChild(row);
            });
          }

          linkedItemsWrapper.appendChild(section);
        });

      bindLinkedItemEvents();
    }

    function bindLinkedItemEvents() {
      linkedItemsWrapper.querySelectorAll('.linked-item-toggle').forEach(toggle => {
        toggle.addEventListener('change', (event) => {
          const target = event.currentTarget;
          const group = state.linkedGroups.find(item => `${item.linked_type}:${item.linked_id}` === target.dataset.groupKey);
          if (!group) return;
          const serviceId = Number(target.dataset.serviceId);
          const existingIndex = group.items.findIndex(item => Number(item.service_id) === serviceId);

          if (target.checked && existingIndex === -1) {
            group.items.push({
              id: null,
              source_type: 'linked',
              service_id: serviceId,
              title: target.dataset.title || '',
              subtitle: target.dataset.subtitle || '',
              is_required: false,
              is_default_selected: true,
              sort_order: group.items.length,
            });
          } else if (!target.checked && existingIndex !== -1) {
            group.items.splice(existingIndex, 1);
          }

          renderSelectedSummary();
          syncHiddenPayload();
        });
      });

      linkedItemsWrapper.querySelectorAll('.linked-item-default').forEach(input => {
        input.addEventListener('change', (event) => {
          const item = findLinkedItem(event.currentTarget.dataset.groupKey, event.currentTarget.dataset.serviceId);
          if (item) {
            item.is_default_selected = event.currentTarget.checked;
            renderSelectedSummary();
            syncHiddenPayload();
          }
        });
      });

      linkedItemsWrapper.querySelectorAll('.linked-item-required').forEach(input => {
        input.addEventListener('change', (event) => {
          const item = findLinkedItem(event.currentTarget.dataset.groupKey, event.currentTarget.dataset.serviceId);
          if (item) {
            item.is_required = event.currentTarget.checked;
            renderSelectedSummary();
            syncHiddenPayload();
          }
        });
      });
    }

    function findLinkedItem(groupKey, serviceId) {
      const group = state.linkedGroups.find(item => `${item.linked_type}:${item.linked_id}` === groupKey);
      if (!group) return null;
      return group.items.find(item => Number(item.service_id) === Number(serviceId)) || null;
    }

    function renderSelectedSummary() {
      linkedSelectedSummary.innerHTML = '';
      const selections = state.linkedGroups
        .flatMap(group => (group.items || []).map(item => ({
          key: `${group.linked_type}:${group.linked_id}:${item.service_id}`,
          label: item.title || item.name || `Service #${item.service_id}`,
          groupTitle: group.title || resolveGroupTitle(group),
        })));

      if (!selections.length) {
        linkedSelectedSummary.innerHTML = '<span class="package-helper">No services selected yet.</span>';
        return;
      }

      selections.forEach(selection => {
        const pill = document.createElement('span');
        pill.className = 'selected-summary-pill';
        pill.textContent = `${selection.groupTitle}: ${selection.label}`;
        linkedSelectedSummary.appendChild(pill);
      });
    }

    function renderCustomGroups() {
      customGroupsList.innerHTML = '';
      const showEmpty = !state.customGroups.length;
      customGroupsEmpty.classList.toggle('section-hidden', !showEmpty);
      if (showEmpty) return;

      state.customGroups.forEach((group, groupIndex) => {
        const wrap = document.createElement('div');
        wrap.className = 'custom-group mb-3';
        wrap.innerHTML = `
          <div class="d-flex justify-content-between align-items-start gap-2 mb-3">
            <div class="row flex-grow-1">
              <div class="col-md-6 mb-2">
                <label class="form-label">Group Title</label>
                <input type="text" class="form-control custom-group-title" value="${escapeAttr(group.title)}" data-group-index="${groupIndex}">
              </div>
              <div class="col-md-6 mb-2">
                <label class="form-label">Subtitle</label>
                <input type="text" class="form-control custom-group-subtitle" value="${escapeAttr(group.subtitle || '')}" data-group-index="${groupIndex}">
              </div>
            </div>
            <button type="button" class="btn btn-outline-danger btn-sm remove-custom-group" data-group-index="${groupIndex}">Remove</button>
          </div>
          <div class="d-flex justify-content-between align-items-center mb-3">
            <span class="builder-chip">${group.items.length} custom item${group.items.length === 1 ? '' : 's'}</span>
            <button type="button" class="btn btn-outline-primary btn-sm add-custom-item" data-group-index="${groupIndex}">Add Item</button>
          </div>
          <div class="custom-items-list"></div>
        `;

        const itemsList = wrap.querySelector('.custom-items-list');
        group.items.forEach((item, itemIndex) => {
          const itemWrap = document.createElement('div');
          itemWrap.className = 'custom-item mb-3';
          itemWrap.innerHTML = `
            <div class="d-flex justify-content-between align-items-start gap-2">
              <div class="row flex-grow-1">
                <div class="col-md-4 mb-2">
                  <label class="form-label">Item Title</label>
                  <input type="text" class="form-control custom-item-name" value="${escapeAttr(item.name)}" data-group-index="${groupIndex}" data-item-index="${itemIndex}">
                </div>
                <div class="col-md-4 mb-2">
                  <label class="form-label">Subtitle</label>
                  <input type="text" class="form-control custom-item-subtitle" value="${escapeAttr(item.subtitle || '')}" data-group-index="${groupIndex}" data-item-index="${itemIndex}">
                </div>
                <div class="col-md-2 mb-2">
                  <label class="form-label">Price</label>
                  <input type="number" step="0.01" min="0" class="form-control custom-item-price" value="${escapeAttr(item.custom_price ?? '')}" data-group-index="${groupIndex}" data-item-index="${itemIndex}">
                </div>
                <div class="col-md-2 mb-2">
                  <label class="form-label">Duration</label>
                  <input type="number" min="0" class="form-control custom-item-duration" value="${escapeAttr(item.custom_duration_minutes ?? '')}" data-group-index="${groupIndex}" data-item-index="${itemIndex}">
                </div>
                <div class="col-md-5 mb-2 d-flex gap-3 align-items-center">
                  <label class="form-check mb-0">
                    <input type="checkbox" class="form-check-input custom-item-default" data-group-index="${groupIndex}" data-item-index="${itemIndex}" ${item.is_default_selected ? 'checked' : ''}>
                    <span class="form-check-label">Default selected</span>
                  </label>
                  <label class="form-check mb-0">
                    <input type="checkbox" class="form-check-input custom-item-required" data-group-index="${groupIndex}" data-item-index="${itemIndex}" ${item.is_required ? 'checked' : ''}>
                    <span class="form-check-label">Required</span>
                  </label>
                </div>
              </div>
              <button type="button" class="btn btn-outline-danger btn-sm remove-custom-item" data-group-index="${groupIndex}" data-item-index="${itemIndex}">Remove</button>
            </div>
            <div class="mt-3">
              <div class="d-flex justify-content-between align-items-center mb-2">
                <div class="linked-item-meta">Manual options are only for hybrid/manual custom rows.</div>
                <button type="button" class="btn btn-outline-secondary btn-sm add-custom-option" data-group-index="${groupIndex}" data-item-index="${itemIndex}">Add Option</button>
              </div>
              <div class="custom-options-list"></div>
            </div>
          `;

          const optionList = itemWrap.querySelector('.custom-options-list');
          item.options.forEach((option, optionIndex) => {
            const optionWrap = document.createElement('div');
            optionWrap.className = 'custom-option mb-2';
            optionWrap.innerHTML = `
              <div class="row align-items-end">
                <div class="col-md-3 mb-2">
                  <label class="form-label">Option Name</label>
                  <input type="text" class="form-control custom-option-name" value="${escapeAttr(option.name)}" data-group-index="${groupIndex}" data-item-index="${itemIndex}" data-option-index="${optionIndex}">
                </div>
                <div class="col-md-3 mb-2">
                  <label class="form-label">Subtitle</label>
                  <input type="text" class="form-control custom-option-subtitle" value="${escapeAttr(option.subtitle || '')}" data-group-index="${groupIndex}" data-item-index="${itemIndex}" data-option-index="${optionIndex}">
                </div>
                <div class="col-md-2 mb-2">
                  <label class="form-label">Price</label>
                  <input type="number" step="0.01" min="0" class="form-control custom-option-price" value="${escapeAttr(option.price ?? '')}" data-group-index="${groupIndex}" data-item-index="${itemIndex}" data-option-index="${optionIndex}">
                </div>
                <div class="col-md-2 mb-2">
                  <label class="form-label">Duration</label>
                  <input type="number" min="0" class="form-control custom-option-duration" value="${escapeAttr(option.duration_minutes ?? '')}" data-group-index="${groupIndex}" data-item-index="${itemIndex}" data-option-index="${optionIndex}">
                </div>
                <div class="col-md-1 mb-2 text-right">
                  <button type="button" class="btn btn-outline-danger btn-sm remove-custom-option" data-group-index="${groupIndex}" data-item-index="${itemIndex}" data-option-index="${optionIndex}">×</button>
                </div>
                <div class="col-md-3">
                  <label class="form-check mb-0">
                    <input type="checkbox" class="form-check-input custom-option-default" data-group-index="${groupIndex}" data-item-index="${itemIndex}" data-option-index="${optionIndex}" ${option.is_default ? 'checked' : ''}>
                    <span class="form-check-label">Default option</span>
                  </label>
                </div>
              </div>
            `;
            optionList.appendChild(optionWrap);
          });

          itemsList.appendChild(itemWrap);
        });

        customGroupsList.appendChild(wrap);
      });

      bindCustomEvents();
    }

    function bindCustomEvents() {
      customGroupsList.querySelectorAll('.custom-group-title').forEach(input => input.addEventListener('input', e => updateCustomGroupField(e, 'title')));
      customGroupsList.querySelectorAll('.custom-group-subtitle').forEach(input => input.addEventListener('input', e => updateCustomGroupField(e, 'subtitle')));
      customGroupsList.querySelectorAll('.remove-custom-group').forEach(button => button.addEventListener('click', e => {
        state.customGroups.splice(Number(e.currentTarget.dataset.groupIndex), 1);
        renderCustomGroups();
        syncHiddenPayload();
      }));
      customGroupsList.querySelectorAll('.add-custom-item').forEach(button => button.addEventListener('click', e => {
        const group = state.customGroups[Number(e.currentTarget.dataset.groupIndex)];
        if (!group) return;
        group.items.push(defaultCustomItem());
        renderCustomGroups();
        syncHiddenPayload();
      }));
      customGroupsList.querySelectorAll('.remove-custom-item').forEach(button => button.addEventListener('click', e => {
        const group = state.customGroups[Number(e.currentTarget.dataset.groupIndex)];
        if (!group) return;
        group.items.splice(Number(e.currentTarget.dataset.itemIndex), 1);
        renderCustomGroups();
        syncHiddenPayload();
      }));
      customGroupsList.querySelectorAll('.add-custom-option').forEach(button => button.addEventListener('click', e => {
        const item = getCustomItem(e.currentTarget.dataset.groupIndex, e.currentTarget.dataset.itemIndex);
        if (!item) return;
        item.options.push(defaultCustomOption());
        renderCustomGroups();
        syncHiddenPayload();
      }));
      customGroupsList.querySelectorAll('.remove-custom-option').forEach(button => button.addEventListener('click', e => {
        const item = getCustomItem(e.currentTarget.dataset.groupIndex, e.currentTarget.dataset.itemIndex);
        if (!item) return;
        item.options.splice(Number(e.currentTarget.dataset.optionIndex), 1);
        renderCustomGroups();
        syncHiddenPayload();
      }));

      [['.custom-item-name', 'name'], ['.custom-item-subtitle', 'subtitle'], ['.custom-item-price', 'custom_price'], ['.custom-item-duration', 'custom_duration_minutes']].forEach(([selector, field, numeric]) => {
        customGroupsList.querySelectorAll(selector).forEach(input => input.addEventListener('input', e => updateCustomItemField(e, field, numeric)));
      });
      customGroupsList.querySelectorAll('.custom-item-default').forEach(input => input.addEventListener('change', e => updateCustomItemCheck(e, 'is_default_selected')));
      customGroupsList.querySelectorAll('.custom-item-required').forEach(input => input.addEventListener('change', e => updateCustomItemCheck(e, 'is_required')));

      [['.custom-option-name', 'name'], ['.custom-option-subtitle', 'subtitle'], ['.custom-option-price', 'price'], ['.custom-option-duration', 'duration_minutes']].forEach(([selector, field, numeric]) => {
        customGroupsList.querySelectorAll(selector).forEach(input => input.addEventListener('input', e => updateCustomOptionField(e, field, numeric)));
      });
      customGroupsList.querySelectorAll('.custom-option-default').forEach(input => input.addEventListener('change', e => updateCustomOptionCheck(e, 'is_default')));
    }

    function updateCustomGroupField(event, field, numeric = false) {
      const index = Number(event.currentTarget.dataset.groupIndex);
      if (!state.customGroups[index]) return;
      state.customGroups[index][field] = numeric ? Number(event.currentTarget.value || 0) : event.currentTarget.value;
      syncHiddenPayload();
    }

    function updateCustomItemField(event, field, numeric = false) {
      const item = getCustomItem(event.currentTarget.dataset.groupIndex, event.currentTarget.dataset.itemIndex);
      if (!item) return;
      item[field] = numeric ? Number(event.currentTarget.value || 0) : event.currentTarget.value;
      syncHiddenPayload();
    }

    function updateCustomItemCheck(event, field) {
      const item = getCustomItem(event.currentTarget.dataset.groupIndex, event.currentTarget.dataset.itemIndex);
      if (!item) return;
      item[field] = event.currentTarget.checked;
      syncHiddenPayload();
    }

    function updateCustomOptionField(event, field, numeric = false) {
      const option = getCustomOption(event.currentTarget.dataset.groupIndex, event.currentTarget.dataset.itemIndex, event.currentTarget.dataset.optionIndex);
      if (!option) return;
      option[field] = numeric ? Number(event.currentTarget.value || 0) : event.currentTarget.value;
      syncHiddenPayload();
    }

    function updateCustomOptionCheck(event, field) {
      const option = getCustomOption(event.currentTarget.dataset.groupIndex, event.currentTarget.dataset.itemIndex, event.currentTarget.dataset.optionIndex);
      if (!option) return;
      option[field] = event.currentTarget.checked;
      syncHiddenPayload();
    }

    function getCustomItem(groupIndex, itemIndex) {
      return state.customGroups[Number(groupIndex)]?.items?.[Number(itemIndex)] || null;
    }

    function getCustomOption(groupIndex, itemIndex, optionIndex) {
      return getCustomItem(groupIndex, itemIndex)?.options?.[Number(optionIndex)] || null;
    }

    function defaultCustomGroup() {
      return { id: null, source_type: 'custom', title: '', subtitle: '', sort_order: state.customGroups.length, items: [defaultCustomItem()] };
    }

    function defaultCustomItem() {
      return { id: null, source_type: 'custom', name: '', subtitle: '', custom_price: '', custom_duration_minutes: '', is_required: false, is_default_selected: true, sort_order: 0, options: [] };
    }

    function defaultCustomOption() {
      return { id: null, name: '', subtitle: '', price: '', duration_minutes: '', is_default: false, sort_order: 0 };
    }

    function syncHiddenPayload() {
      hiddenPayload.innerHTML = '';
      const mode = getCurrentMode();

      if (mode === 'hierarchy' || mode === 'hybrid') {
        appendHidden('contexts[0][id]', state.context.id ?? '');
        appendHidden('contexts[0][context_type]', contextTypeSelect.value || '');
        appendHidden('contexts[0][context_id]', contextIdSelect.value || '');
        appendHidden('contexts[0][sort_order]', state.context.sort_order ?? 0);
      }

      const groupsToPersist = [];
      if (mode === 'hierarchy' || mode === 'hybrid') {
        state.linkedGroups.filter(group => group.items.length > 0).sort((a, b) => a.sort_order - b.sort_order).forEach(group => groupsToPersist.push(group));
      }
      if (mode === 'hybrid' || mode === 'manual') {
        state.customGroups.forEach(group => groupsToPersist.push(group));
      }

      groupsToPersist.forEach((group, groupIndex) => {
        appendHidden(`groups[${groupIndex}][id]`, group.id ?? '');
        appendHidden(`groups[${groupIndex}][source_type]`, group.source_type || 'custom');
        appendHidden(`groups[${groupIndex}][linked_type]`, group.linked_type ?? '');
        appendHidden(`groups[${groupIndex}][linked_id]`, group.linked_id ?? '');
        appendHidden(`groups[${groupIndex}][title]`, group.source_type === 'custom' ? (group.title || '') : '');
        appendHidden(`groups[${groupIndex}][subtitle]`, group.source_type === 'custom' ? (group.subtitle || '') : '');
        appendHidden(`groups[${groupIndex}][sort_order]`, group.sort_order ?? groupIndex);

        (group.items || []).forEach((item, itemIndex) => {
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][id]`, item.id ?? '');
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][source_type]`, item.source_type || (group.source_type === 'linked' ? 'linked' : 'custom'));
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][service_id]`, item.service_id ?? '');
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][name]`, item.name || item.title || '');
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][subtitle]`, item.subtitle || '');
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][custom_price]`, item.custom_price ?? '');
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][custom_duration_minutes]`, item.custom_duration_minutes ?? '');
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][is_required]`, item.is_required ? 1 : 0);
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][is_default_selected]`, item.is_default_selected ? 1 : 0);
          appendHidden(`groups[${groupIndex}][items][${itemIndex}][sort_order]`, item.sort_order ?? itemIndex);

          (item.options || []).forEach((option, optionIndex) => {
            appendHidden(`groups[${groupIndex}][items][${itemIndex}][options][${optionIndex}][id]`, option.id ?? '');
            appendHidden(`groups[${groupIndex}][items][${itemIndex}][options][${optionIndex}][name]`, option.name || '');
            appendHidden(`groups[${groupIndex}][items][${itemIndex}][options][${optionIndex}][subtitle]`, option.subtitle || '');
            appendHidden(`groups[${groupIndex}][items][${itemIndex}][options][${optionIndex}][price]`, option.price ?? '');
            appendHidden(`groups[${groupIndex}][items][${itemIndex}][options][${optionIndex}][duration_minutes]`, option.duration_minutes ?? '');
            appendHidden(`groups[${groupIndex}][items][${itemIndex}][options][${optionIndex}][is_default]`, option.is_default ? 1 : 0);
            appendHidden(`groups[${groupIndex}][items][${itemIndex}][options][${optionIndex}][sort_order]`, option.sort_order ?? optionIndex);
          });
        });
      });
    }

    function appendHidden(name, value) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = name;
      input.value = value;
      hiddenPayload.appendChild(input);
    }

    function resolveGroupTitle(group) {
      const match = state.availableGroups.find(item => item.type === group.linked_type && Number(item.id) === Number(group.linked_id));
      return match?.title || group.title || `Linked Group #${group.linked_id}`;
    }

    function formatNumber(value) {
      const number = Number(value || 0);
      return Number.isInteger(number) ? number.toString() : number.toFixed(2);
    }

    function escapeHtml(value) {
      return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }

    function escapeAttr(value) {
      return escapeHtml(value);
    }

    contextTypeSelect.addEventListener('change', () => {
      state.context.context_type = contextTypeSelect.value;
      state.context.context_id = '';
      contextIdSelect.value = '';
      populateContextOptions();
      state.availableGroups = [];
      state.linkedGroups = [];
      state.itemCandidates = {};
      renderLinkedGroups();
      renderLinkedItems();
      syncHiddenPayload();
    });

    contextIdSelect.addEventListener('change', async () => {
      state.context.context_id = contextIdSelect.value;
      state.availableGroups = [];
      state.linkedGroups = [];
      state.itemCandidates = {};
      await fetchLinkedGroups();
      syncHiddenPayload();
    });

    modeSelect.addEventListener('change', () => {
      setSectionVisibility();
      syncHiddenPayload();
    });

    document.getElementById('add-custom-group').addEventListener('click', () => {
      state.customGroups.push(defaultCustomGroup());
      renderCustomGroups();
      syncHiddenPayload();
    });

    form.addEventListener('submit', () => {
      syncHiddenPayload();
    });

    contextTypeSelect.value = state.context.context_type || '';
    populateContextOptions();
    if (state.context.context_id) {
      contextIdSelect.value = String(state.context.context_id);
    }
    setSectionVisibility();
    renderCustomGroups();
    syncHiddenPayload();
    if (contextTypeSelect.value && contextIdSelect.value) {
      fetchLinkedGroups();
    } else {
      renderLinkedGroups();
      renderLinkedItems();
    }
  })();
</script>
