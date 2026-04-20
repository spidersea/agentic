---
description: 界面加固操作指南细节 (代码片段与测试清单) (从 SKILL.md 下沉)
---

# 界面加固细节指南 (Harden Details)

## 1. 代码片段与策略

### Text Overflow & Wrapping
```css
/* Single line with ellipsis */
.truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
/* Multi-line with clamp */
.line-clamp { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
/* Allow wrapping */
.wrap { word-wrap: break-word; overflow-wrap: break-word; hyphens: auto; }
/* Flex/Grid prevent overflow */
.flex-item { min-width: 0; overflow: hidden; }
```

### Internationalization (i18n)
```css
/* RTL Logical Properties */
margin-inline-start: 1rem;
padding-inline: 1rem;
border-inline-end: 1px solid;
[dir="rtl"] .arrow { transform: scaleX(-1); }
```
```javascript
// Formatting
new Intl.DateTimeFormat('de-DE').format(date); // 15.1.2024
new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(1234.56);
```

### Error Recovery
```jsx
// Error states with recovery
{error && (
  <ErrorMessage>
    <p>Failed to load data. {error.message}</p>
    <button onClick={retry}>Try again</button>
  </ErrorMessage>
)}
```

### Accessibility Resilience
```css
/* Motion sensitivity handling */
@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

### Performance Resilence
```javascript
// Debounce search input
const debouncedSearch = debounce(handleSearch, 300);
// Throttle scroll handler
const throttledScroll = throttle(handleScroll, 100);
```

## 2. 极限验证清单 (Verify Hardening Checklist)

- **Long text**: names with 100+ characters, descriptions exceeding container limits
- **International**: German (+30% length), RTL (Arabic/Hebrew), CJK (Chinese/Japanese/Korean)
- **Special Chars**: Emojis (take 2-4 bytes), HTML injection attempts
- **Network limits**: Offline mode, 3G throttle, timeout triggering
- **Data limits**: 0 items (empty state), 1000+ items (paging/virtualization), missing fields
- **Concurrent**: Double-submit prevention (rapid successive clicks)
- **Error paths**: Forced 400, 401, 403, 404, 429, 500 status codes handling
- **Accessibility**: Keyboard-only traversal, screen reader (ARIA), high contrast simulation
