$indexPath = 'C:\xampp\htdocs\bellavellaa\resources\views\media\index.blade.php'
$editPath = 'C:\xampp\htdocs\bellavellaa\resources\views\media\edit.blade.php'

$index = Get-Content -Raw $indexPath
$oldIndex = @'
                <td class="px-4 py-4">
                  <div class="media-preview flex items-center justify-center bg-gray-100">
                    @if(!empty($m->file_path) || !empty($m->url))
                    <img src="{{ \App\Support\MediaPathNormalizer::url($m->file_path ?? $m->url) }}" class="w-full h-full object-cover rounded-xl" alt="">
                    @else
                    <i data-lucide="{{ $typeIcon }}" class="w-5 h-5 text-gray-400"></i>
                    @endif
                  </div>
                </td>
'@
$newIndex = @'
                <td class="px-4 py-4">
                  <div class="media-preview flex items-center justify-center bg-gray-100 overflow-hidden rounded-xl">
                    @php
                      $previewUrl = \App\Support\MediaPathNormalizer::url($m->file_path ?? $m->url);
                    @endphp
                    @if($previewUrl)
                      @if($typeVal === 'video')
                        <video class="w-full h-full object-cover rounded-xl" muted playsinline preload="metadata">
                          <source src="{{ $previewUrl }}" type="video/mp4">
                        </video>
                      @else
                        <img src="{{ $previewUrl }}" class="w-full h-full object-cover rounded-xl" alt="">
                      @endif
                    @else
                    <i data-lucide="{{ $typeIcon }}" class="w-5 h-5 text-gray-400"></i>
                    @endif
                  </div>
                </td>
'@

if (-not $index.Contains($oldIndex)) {
  throw 'Media index replacement failed.'
}

$index = $index.Replace($oldIndex, $newIndex)
Set-Content -LiteralPath $indexPath -Value $index

$edit = Get-Content -Raw $editPath
$oldEdit = @'
    const existingFileUrl = "{{ $media->url ?? $media->file_url ?? '' }}";
'@
$newEdit = @'
    const existingFileUrl = @json(\App\Support\MediaPathNormalizer::url($media->url ?? $media->file_url));
'@

if (-not $edit.Contains($oldEdit)) {
  throw 'Media edit replacement failed.'
}

$edit = $edit.Replace($oldEdit, $newEdit)
Set-Content -LiteralPath $editPath -Value $edit
