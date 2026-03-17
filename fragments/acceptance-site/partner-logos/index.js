const wrapper = fragmentElement.querySelector('.logos-wrapper');

if (wrapper) {
    const clone = wrapper.cloneNode(true);
    
    clone.setAttribute('aria-hidden', 'true');
    
    // Remove editable IDs from clone to avoid Liferay conflicts
    clone.querySelectorAll('[data-lfr-editable-id]').forEach(el => {
        el.removeAttribute('data-lfr-editable-id');
    });
    
    wrapper.parentNode.appendChild(clone);
}
