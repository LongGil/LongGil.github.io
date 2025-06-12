const spinnerWarapperEl = document.querySelector(".spinner-wrapper");


window.addEventListener("load", () => {
    spinnerWarapperEl.style.opacity = "0";

    setTimeout(() => {
        spinnerWarapperEl.style.display = "none";
    }, 200);
});