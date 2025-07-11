# Memory Management System (x86 AT&T Assembly)

A university assignment for Computer System Architecture, implementing file storage and management in assembly language.

---

## Official Project Specification

- **Project Requirements**  
  Detailed PDF covering unidimensional and bidimensional memory management, operations like file placement, deletion, descriptor lookup, and defragmentation.  
  [Official Project Requirements](https://cs.unibuc.ro/~crusu/asc/Arhitectura%20Sistemelor%20de%20Calcul%20%28ASC%29%20-%20Tema%20Laborator%202024.pdf)

**Highlights from the spec:**
- Supports up to **255 files**, storage device of **8 MB**, and **8 kB blocks**
- **Unidimensional mode**: contiguous file storage with operations: find, allocate, delete, defragment
- **Bidimensional mode**: 8 MB × 8 MB grid of blocks; contiguous row-wise allocation, with similar operations

**Supported operations and their query codes:**
- 1: **ADD** which allocates memory for one or more files
- 2: **GET** returns the location (start, end) or ((start_x, start_y), (end_x, end_y)) of your file in memory
- 3: **DELETE** deletes a file from memory
- 4: **DEFRAGMENTATION** tries to bring files closer together to remove the gaps between files
---

## Test Suites and Validators

- [**Official Project Tester**](https://github.com/iancuivasciuc/csa/tree/master/project)  
  A comprehensive testing tool to validate correct functionality—placement, deletion, boundary cases, fragmentation, etc.

- [**Unofficial Tester**](https://github.com/aleeecsss/testare_proiect_asc_2)  
  Alternative validation script maintained by the community.

---
