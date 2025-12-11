import os
import json
import re
import pandas as pd
import matplotlib.pyplot as plt
import glob
import numpy as np
import platform
from datetime import datetime
try:
    from adjustText import adjust_text
except ImportError:
    adjust_text = None
    

# Use absolute path relative to this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(SCRIPT_DIR, "results")

def parse_model_info(model_path):
    """Extract size and quantization from model path."""
    # Example: ../models/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf
    filename = os.path.basename(model_path).lower()
    
    # Extract Size
    size_match = re.search(r"(\d+(\.\d+)?)b", filename)
    size = size_match.group(1) + "B" if size_match else "Unknown"
    
    # Extract Quantization
    # Look for patterns like q4_k_m, q8_0, q2_k
    quant_match = re.search(r"(q\d+_[k0-9a-z_]+)", filename)
    quant = quant_match.group(1) if quant_match else "Unknown"
    
    return size, quant

import argparse

def load_results(session_id=None):
    data = []
    
    if session_id:
        search_path = os.path.join(RESULTS_DIR, session_id, "*", "results.json")
    else:
        # Recursive search to find all results.json in subdirectories
        search_path = os.path.join(RESULTS_DIR, "**", "results.json")
        
    files = glob.glob(search_path, recursive=True)
    
    print(f"Found {len(files)} result files in {search_path}")
    
    for f in files:
        try:
            with open(f, 'r') as file:
                res = json.load(file)
                
            model_path = res.get('model_path', '')
            size, quant = parse_model_info(model_path)
            
            data.append({
                'Model Size': size,
                'Quantization': quant,
                'Language': res.get('language', 'Unknown'),
                'Accuracy': res.get('scalpel_accuracy', 0.0),
                'Latency (ms)': res.get('avg_latency_ms', 0.0),
                'Improvement': res.get('improvement', 0.0),
                'timestamp': res.get('timestamp', ''),
                'Path': f
            })
        except Exception as e:
            print(f"Error reading {f}: {e}")
            
    df = pd.DataFrame(data)
    
    # Deduplicate: Keep only the latest run for each (Size, Quant, Language) combination
    if not df.empty and 'timestamp' in df.columns:
        df = df.sort_values('timestamp', ascending=False)
        df = df.drop_duplicates(subset=['Model Size', 'Quantization', 'Language'], keep='first')
        
    return df

def generate_table(df, output_dir):
    if df.empty:
        print("No results found.")
        return

    # Sort by Language then Accuracy descending
    df_sorted = df.sort_values(by=['Language', 'Accuracy'], ascending=[True, False])
    
    # Select relevant columns
    table_df = df_sorted[['Language', 'Model Size', 'Quantization', 'Accuracy', 'Latency (ms)', 'Improvement']].copy()
    
    # Format Accuracy and Improvement as percentages
    table_df['Accuracy'] = table_df['Accuracy'].apply(lambda x: f"{x:.2%}")
    table_df['Improvement'] = table_df['Improvement'].apply(lambda x: f"{x:+.2%}")
    table_df['Latency (ms)'] = table_df['Latency (ms)'].apply(lambda x: f"{x:.1f}")
    
    markdown_table = table_df.to_markdown(index=False)
    
    print("\n### Summary Table")
    print(markdown_table)
    
    os.makedirs(output_dir, exist_ok=True)
    with open(os.path.join(output_dir, "summary_table.md"), "w") as f:
        f.write("# Experiment Results Summary\n\n")
        
        # Add Metadata Section
        f.write("## Configuration Details\n")
        f.write(f"- **Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"- **Host Machine**: {platform.node()}\n")
        f.write(f"- **Model Family**: Qwen2.5-Coder\n")
        f.write(f"- **Context Window**: 512 tokens (Fixed)\n")
        f.write("\n")
        
        f.write(markdown_table)
    print(f"Table saved to {os.path.join(output_dir, 'summary_table.md')}")

def generate_plots(df, output_dir):
    if df.empty:
        return

    os.makedirs(output_dir, exist_ok=True)

    # Ensure numeric types
    df['Size Num'] = df['Model Size'].apply(lambda x: float(x.replace('B', '')))
    
    # Define metadata text once
    meta_text = f"Generated: {datetime.now().strftime('%Y-%m-%d')} | Host: {platform.node()} | Hardware: Apple M3 Pro (36GB RAM) | Model: Qwen2.5-Coder-Instruct"

    # 1. Grouped Bar Chart: Accuracy by Size & Quant (Per Language)
    languages = df['Language'].unique()
    
    for lang in languages:
        lang_df = df[df['Language'] == lang]
        if lang_df.empty:
            continue
            
        plt.figure(figsize=(10, 6))
        
        sizes = sorted(lang_df['Model Size'].unique(), key=lambda x: float(x.replace('B', '')))
        
        # Pivot for plotting
        pivot_df = lang_df.pivot(index='Model Size', columns='Quantization', values='Accuracy')
        # Reorder index to match size order
        pivot_df = pivot_df.reindex(sizes)
        
        ax = pivot_df.plot(kind='bar', figsize=(10, 6))
        
        # Add LSP Baseline Line
        lsp_acc = lang_df['LSP Accuracy'].mean()
        plt.axhline(y=lsp_acc, color='r', linestyle='--', label=f'LSP Baseline ({lsp_acc:.1%})')
        
        plt.title(f'Accuracy by Model Size & Quantization ({lang})')
        plt.ylabel('Accuracy')
        plt.xlabel('Model Size')
        plt.xticks(rotation=0)
        plt.grid(axis='y', linestyle='--', alpha=0.7)
        # Move legend outside to prevent overshadowing bars
        plt.legend(title='Quantization', bbox_to_anchor=(1.05, 1), loc='upper left')
        
        # Add Metadata Footer
        plt.figtext(0.5, 0.01, meta_text, ha='center', fontsize=8, color='gray')
        
        plt.tight_layout()
        # Adjust bottom to make room for footer
        plt.subplots_adjust(bottom=0.15)
        
        plt.savefig(os.path.join(output_dir, f"accuracy_bar_chart_{lang}.png"))
        print(f"Bar chart saved to {os.path.join(output_dir, f'accuracy_bar_chart_{lang}.png')}")
        
        # 1b. Grouped Bar Chart: Latency by Size & Quant (Per Language)
        plt.figure(figsize=(10, 6))
        
        # Pivot for plotting
        pivot_df_lat = lang_df.pivot(index='Model Size', columns='Quantization', values='Latency (ms)')
        # Reorder index to match size order
        pivot_df_lat = pivot_df_lat.reindex(sizes)
        
        pivot_df_lat.plot(kind='bar', figsize=(10, 6))
        
        plt.title(f'Latency by Model Size & Quantization ({lang})')
        plt.ylabel('Latency (ms)')
        plt.xlabel('Model Size')
        plt.xticks(rotation=0)
        plt.grid(axis='y', linestyle='--', alpha=0.7)
        # Move legend outside
        plt.legend(title='Quantization', bbox_to_anchor=(1.05, 1), loc='upper left')
        
        # Add Metadata Footer
        plt.figtext(0.5, 0.01, meta_text, ha='center', fontsize=8, color='gray')
        
        plt.tight_layout()
        # Adjust bottom to make room for footer
        plt.subplots_adjust(bottom=0.15)
        
        plt.savefig(os.path.join(output_dir, f"latency_bar_chart_{lang}.png"))
        print(f"Latency Bar chart saved to {os.path.join(output_dir, f'latency_bar_chart_{lang}.png')}")
    
    # 2. Scatter Plot: Accuracy vs Latency (Combined)
    # Helper function to generate scatter plot
    def create_scatter_plot(use_log_scale, output_filename, title_suffix):
        plt.figure(figsize=(12, 8))
        
        markers = {'python': 'o', 'java': '^', 'Unknown': 's'}
        quants = sorted(df['Quantization'].unique())
        
        # Create a color map for quantizations
        colors = plt.cm.viridis(np.linspace(0, 1, len(quants)))
        quant_colors = dict(zip(quants, colors))

        texts = []
        for idx, row in df.iterrows():
            plt.scatter(
                row['Latency (ms)'], 
                row['Accuracy'], 
                color=quant_colors.get(row['Quantization'], 'black'),
                marker=markers.get(row['Language'], 'o'),
                s=row['Size Num'] * 100, # Marker size proportional to model size
                alpha=0.7,
                label=f"{row['Quantization']} ({row['Language']})" 
            )
            
            # Prepare text for adjust_text
            texts.append(plt.text(
                row['Latency (ms)'], 
                row['Accuracy'],
                f"{row['Model Size']}\n{row['Quantization']}",
                fontsize=7
            ))

        if adjust_text:
            adjust_text(texts, 
                       arrowprops=dict(arrowstyle='-', color='gray', alpha=0.5),
                       force_text=(1.0, 1.2),  # Stronger text repulsion
                       expand_points=(1.5, 1.5), # Treat points as larger obstacles
                       lim=1000 # More iterations
            )

        # Custom Legend
        from matplotlib.lines import Line2D
        legend_elements = [Line2D([0], [0], marker='o', color='w', label='Python', markerfacecolor='gray', markersize=10),
                           Line2D([0], [0], marker='^', color='w', label='Java', markerfacecolor='gray', markersize=10)]
        
        for q, c in quant_colors.items():
            legend_elements.append(Line2D([0], [0], marker='o', color='w', label=q, markerfacecolor=c, markersize=10))

        plt.legend(handles=legend_elements, title='Legend', loc='lower right')

        plt.title(f'Accuracy vs. Latency Trade-off {title_suffix}')
        plt.ylabel('Accuracy')
        
        if use_log_scale:
            plt.xlabel('Latency (ms) - Log Scale')
            plt.xscale('log')
            ax = plt.gca()
            from matplotlib.ticker import ScalarFormatter
            ax.xaxis.set_major_formatter(ScalarFormatter())
        else:
            plt.xlabel('Latency (ms)')
            
        plt.grid(True, linestyle='--', alpha=0.5, which="both")
        
        # Add Metadata Footer
        plt.figtext(0.5, 0.01, meta_text, ha='center', fontsize=8, color='gray')
        
        plt.tight_layout()
        plt.subplots_adjust(bottom=0.1)
        
        plt.savefig(os.path.join(output_dir, output_filename))
        print(f"Scatter plot saved to {os.path.join(output_dir, output_filename)}")

    # Generate Log Scale Plot
    create_scatter_plot(True, "tradeoff_scatter_log.png", "(Log Scale)")
    
    # Generate Linear Scale Plot
    create_scatter_plot(False, "tradeoff_scatter_linear.png", "(Linear Scale)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Visualize Scalpel Results")
    parser.add_argument("--session-id", type=str, default=None, help="Session ID to visualize (e.g. 20241202_123456)")
    parser.add_argument("--output-dir", type=str, default=None, help="Directory to save plots and tables (and load results from)")
    args = parser.parse_args()

    # Determine where to load results from
    if args.session_id:
        # If session ID is explicit, load from there
        search_dir = os.path.join(RESULTS_DIR, args.session_id)
        # Default output dir to that session
        base_output_dir = search_dir
    elif args.output_dir:
        # If output dir is provided, use it as the source AND destination base
        search_dir = args.output_dir
        base_output_dir = args.output_dir
    else:
        # Fallback to all results
        search_dir = RESULTS_DIR
        base_output_dir = RESULTS_DIR

    # Load results from the determined search directory
    # We need to update load_results to accept a directory path instead of just session_id
    # But for now, let's just bypass load_results's session logic if we have a custom dir
    
    data = []
    # Search recursively in the target directory
    search_path = os.path.join(search_dir, "**", "results.json")
    files = glob.glob(search_path, recursive=True)
    
    print(f"Found {len(files)} result files in {search_path}")
    
    for f in files:
        try:
            with open(f, 'r') as json_file:
                res = json.load(json_file)
            
            size, quant = parse_model_info(res.get('model_path', ''))
            
            data.append({
                'Language': res.get('language', 'Unknown'),
                'Model Size': size,
                'Quantization': quant,
                'Accuracy': res.get('scalpel_accuracy', 0.0),
                'LSP Accuracy': res.get('lsp_accuracy', 0.0),
                'Latency (ms)': res.get('avg_latency_ms', 0.0),
                'Improvement': res.get('improvement', 0.0),
                'timestamp': res.get('timestamp', ''),
                'Path': f
            })
        except Exception as e:
            print(f"Error reading {f}: {e}")
            
    df = pd.DataFrame(data)
    
    # Deduplicate: Keep only the latest run for each (Size, Quant, Language) combination
    if not df.empty and 'timestamp' in df.columns:
        df = df.sort_values('timestamp', ascending=False)
        df = df.drop_duplicates(subset=['Model Size', 'Quantization', 'Language'], keep='first')

    # Determine output directory for plots
    if args.output_dir:
        # If user specified a dir, use it
        final_output_dir = os.path.join(args.output_dir, "combined_plots")
    elif args.session_id:
        final_output_dir = os.path.join(RESULTS_DIR, args.session_id, "combined_plots")
    else:
        final_output_dir = os.path.join(RESULTS_DIR, "combined_plots")
        
    os.makedirs(final_output_dir, exist_ok=True)
        
    if not df.empty:
        generate_table(df, final_output_dir)
        generate_plots(df, final_output_dir)
    else:
        print("No results to visualize.")
